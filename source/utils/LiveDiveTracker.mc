import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Live, 1 Hz depth tracking for the current snorkeling session: a
// continuously self-calibrating surface reference (no manual calibration
// step needed), per-dive and per-session max depth, and a dive count.
//
// Reads pressure via the shared getCurrentRawPressure() helper (see
// SimpDepthState.mc), NOT Activity.Info.ambientPressure -- that field's
// two-stage smoothing filter is tuned for hiking-speed changes and badly
// lags a ~1 m/s descent (reads shallow going down, keeps rising after you
// stop). Activity.Info.rawAmbientPressure would avoid that filter, but was
// confirmed empirically (this SDK's simulator) to stay null the whole time
// without an active Activity recording, which this app deliberately isn't.
class LiveDiveTracker {
  const STATE_UNKNOWN = 0;
  const STATE_SURFACE = 1;
  const STATE_SUBMERGED = 2;

  // Rolling-mean window, in samples, for the surface reference.
  private const SURFACE_ROLLING_WINDOW = 10;
  // Consecutive samples past the threshold required before a state
  // transition actually happens, in either direction -- debounces splashes
  // and wrist movement right at the boundary.
  private const TRANSITION_DWELL_SAMPLES = 3;
  // Samples to discard after resurfacing before resuming the rolling mean --
  // a wet, just-surfaced sensor settles slowly.
  private const RESURFACE_SETTLE_SAMPLES = 3;
  // Depth, in meters, marking the surface/submerged boundary.
  private const SUBMERSION_THRESHOLD_METERS = 0.5;
  // Consecutive unreadable samples before giving up on ever calibrating.
  private const MAX_UNSUPPORTED_RETRIES = 10;

  // PLACEHOLDER -- not yet measured in water on any device. Run the
  // Diagnostic page's water test (see README) and replace this with the
  // real saturation ceiling in Pa for the device(s) this is built for.
  // Deliberately conservative (roughly 1.5-2 m of depth) rather than a
  // plausible-looking guess at the sensor's real limit: real underwater use
  // will hit "beyond range" quickly and obviously, which is the point --
  // a loud, honest failure instead of a silently wrong number past the
  // sensor's characterized range.
  private const CEILING_PA = 119000.0;

  private var _state as Number = STATE_UNKNOWN;
  private var _surfaceBuffer as Lang.Array<Number or Float>;
  private var _surfaceBufferIndex as Number = 0;
  private var _surfaceBufferCount as Number = 0;
  private var _surfacePa as Number or Float or Null;
  private var _settleRemaining as Number = 0;
  private var _transitionDwellCount as Number = 0;
  private var _unsupportedRetries as Number = 0;

  private var _maxDepthThisDive as Number or Float or Null;
  private var _maxDepthSession as Number or Float or Null;
  private var _diveCount as Number = 0;

  private var _currentDepth as Number or Float or Null;
  private var _currentBeyondRange as Boolean = false;

  private var _chartSize as Number;
  private var _chartHistory as Lang.Array<Number or Float or Null>;

  private var _systemUnits as System.UnitsSystem;
  private var _waterDensity as Float = FRESH_WATER_DENSITY;

  private var _status as Status;
  private var _timer as Timer.Timer;

  function initialize(chartSize as Number, systemUnits as System.UnitsSystem) {
    self._chartSize = chartSize;
    self._chartHistory = new Lang.Array<Number or Float or Null>[_chartSize];
    self._surfaceBuffer = new Lang.Array<Number or Float>[SURFACE_ROLLING_WINDOW];
    self._systemUnits = systemUnits;
    self._status = new Status();

    updateWaterDensity();

    self._timer = new Timer.Timer();
    sample(); // first reading right away, don't make the user wait 1s
    self._timer.start(method(:sample), 1000, true);
  }

  function updateWaterDensity() as Void {
    var saltWater = Application.Properties.getValue("SaltWater") as Boolean?;
    self._waterDensity = saltWater ? SALT_WATER_DENSITY : FRESH_WATER_DENSITY;
  }

  function sample() as Void {
    var pressure = getCurrentRawPressure();
    if (pressure == null) {
      handleUnreadable();
      return;
    }

    _unsupportedRetries = 0;

    if (pressure >= CEILING_PA) {
      _currentBeyondRange = true;
      _currentDepth = null;
      updateSurfaceState(pressure);
      pushChartSample(null);
      finishSample();
      return;
    }

    _currentBeyondRange = false;
    updateSurfaceState(pressure);

    var depth = null;
    var surfacePa = _surfacePa;
    if (surfacePa != null) {
      var computedDepth = convertToDisplayDepth(pressure - surfacePa);
      if (computedDepth < 0) {
        computedDepth = 0.0;
      }
      depth = computedDepth;

      if (_state == STATE_SUBMERGED) {
        if (
          _maxDepthThisDive == null ||
          computedDepth > (_maxDepthThisDive as Number or Float)
        ) {
          _maxDepthThisDive = computedDepth;
        }
        if (
          _maxDepthSession == null ||
          computedDepth > (_maxDepthSession as Number or Float)
        ) {
          _maxDepthSession = computedDepth;
        }
      }
    }

    _currentDepth = depth;
    pushChartSample(depth);
    finishSample();
  }

  // Sensor not ready / unreadable this tick: hold the last known state and
  // depth, don't touch the reference, don't emit a new value.
  private function handleUnreadable() as Void {
    _unsupportedRetries += 1;
    if (_unsupportedRetries >= MAX_UNSUPPORTED_RETRIES && _state == STATE_UNKNOWN) {
      _status.setCode(Status.UNSUPPORTED);
    }
  }

  private function finishSample() as Void {
    _status.setCode(_state == STATE_UNKNOWN ? Status.CALIBRATING : Status.DONE);
  }

  private function updateSurfaceState(pressure as Number or Float) as Void {
    if (_state == STATE_SUBMERGED) {
      checkResurface(pressure);
      return;
    }

    if (_settleRemaining > 0) {
      _settleRemaining -= 1;
      return;
    }

    addToSurfaceBuffer(pressure);

    if (_state == STATE_UNKNOWN) {
      if (_surfaceBufferCount >= SURFACE_ROLLING_WINDOW) {
        _state = STATE_SURFACE;
      }
      return;
    }

    checkSubmerge(pressure);
  }

  private function checkSubmerge(pressure as Number or Float) as Void {
    var meanPa = surfaceMean();
    if (pressure - meanPa > submersionThresholdPa()) {
      _transitionDwellCount += 1;
      if (_transitionDwellCount >= TRANSITION_DWELL_SAMPLES) {
        _surfacePa = meanPa;
        _state = STATE_SUBMERGED;
        _transitionDwellCount = 0;
        _maxDepthThisDive = null;
      }
    } else {
      _transitionDwellCount = 0;
    }
  }

  private function checkResurface(pressure as Number or Float) as Void {
    var referencePa = _surfacePa;
    if (referencePa == null) {
      return;
    }

    if (pressure - referencePa <= submersionThresholdPa()) {
      _transitionDwellCount += 1;
      if (_transitionDwellCount >= TRANSITION_DWELL_SAMPLES) {
        _state = STATE_SURFACE;
        _transitionDwellCount = 0;
        _diveCount += 1;
        _settleRemaining = RESURFACE_SETTLE_SAMPLES;
        _surfaceBufferCount = 0;
        _surfaceBufferIndex = 0;
      }
    } else {
      _transitionDwellCount = 0;
    }
  }

  private function addToSurfaceBuffer(pressure as Number or Float) as Void {
    _surfaceBuffer[_surfaceBufferIndex] = pressure;
    _surfaceBufferIndex = (_surfaceBufferIndex + 1) % SURFACE_ROLLING_WINDOW;
    if (_surfaceBufferCount < SURFACE_ROLLING_WINDOW) {
      _surfaceBufferCount += 1;
    }
  }

  private function surfaceMean() as Float {
    var sum = 0.0;
    for (var i = 0; i < _surfaceBufferCount; i++) {
      sum += _surfaceBuffer[i];
    }
    return sum / _surfaceBufferCount;
  }

  private function submersionThresholdPa() as Float {
    return SUBMERSION_THRESHOLD_METERS * _waterDensity * GRAVITY;
  }

  private function convertToDisplayDepth(deltaPa as Number or Float) as Float {
    var meters = depthMetersFromPressureDelta(deltaPa, _waterDensity);
    if (_systemUnits == System.UNIT_STATUTE) {
      return meters * METERS_TO_FEET;
    }
    return meters;
  }

  // Scrolling strip-chart buffer: shift left, append the newest sample on
  // the right, so DepthChartDrawable's plain index-to-x mapping reads as a
  // live trace with no wrap seam.
  private function pushChartSample(depth as Number or Float or Null) as Void {
    for (var i = 0; i < _chartSize - 1; i++) {
      _chartHistory[i] = _chartHistory[i + 1];
    }
    _chartHistory[_chartSize - 1] = depth;
  }

  function destroy() as Void {
    _timer.stop();
  }

  function getStatus() as Status {
    return _status;
  }

  function getCurrentDepth() as Number or Float or Null {
    return _currentDepth;
  }

  function isCurrentBeyondRange() as Boolean {
    return _currentBeyondRange;
  }

  function getMaxDepthThisDive() as Number or Float or Null {
    return _maxDepthThisDive;
  }

  function getMaxDepthSession() as Number or Float or Null {
    return _maxDepthSession;
  }

  function getDiveCount() as Number {
    return _diveCount;
  }

  function getChartHistory() as Lang.Array<Number or Float or Null> {
    return _chartHistory;
  }

  function getChartMinimum() as Number or Float or Null {
    var minimum = null;
    for (var i = 0; i < _chartSize; i++) {
      var value = _chartHistory[i];
      if (
        value != null &&
        (minimum == null || (value as Number or Float) < (minimum as Number or Float))
      ) {
        minimum = value;
      }
    }
    return minimum;
  }

  function getChartMaximum() as Number or Float or Null {
    var maximum = null;
    for (var i = 0; i < _chartSize; i++) {
      var value = _chartHistory[i];
      if (
        value != null &&
        (maximum == null || (value as Number or Float) > (maximum as Number or Float))
      ) {
        maximum = value;
      }
    }
    return maximum;
  }

  function getPeriodLabel() as String {
    var minutes = Math.round(_chartSize / 60.0).toNumber();
    if (minutes < 1) {
      minutes = 1;
    }
    return "Live: last " + minutes + " min";
  }
}
