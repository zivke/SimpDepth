import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

class Status {
  enum Code {
    UNKNOWN_ERROR = -6,
    UNSUPPORTED = -5,
    INVALID_DATA = -4,
    NO_MIN_MAX_PRESSURE = -3,
    NO_CURRENT_PRESSURE = -2,
    NO_START_END_TIME = -1,
    INITIALIZING = 0,
    LOADING = 1,
    DONE = 2,
    CALIBRATING = 3,
  }

  private var _code as Code = INITIALIZING;

  function getCode() as Code {
    return _code;
  }

  function setCode(code as Code) {
    self._code = code;
    WatchUi.requestUpdate();
  }

  function hasError() {
    return _code < 0;
  }

  function getMessage() as String {
    var message = "";
    if (_code < 0) {
      message = "Error: ";
    }

    switch (self._code) {
      case UNKNOWN_ERROR:
        message += "Unknown";
        break;
      case UNSUPPORTED:
        message += "Sensors not supported";
        break;
      case INVALID_DATA:
        message += "Invalid data";
        break;
      case NO_MIN_MAX_PRESSURE:
        message += "No minimum or maximum pressure";
        break;
      case NO_CURRENT_PRESSURE:
        message += "No current pressure reading";
        break;
      case NO_START_END_TIME:
        message += "No start or end time";
        break;
      case INITIALIZING:
        message += "Initializing...";
        break;
      case LOADING:
        message += "Loading...";
        break;
      case DONE:
        message += "Done";
        break;
      case CALIBRATING:
        message += "Calibrating...";
        break;
      default: {
        message += "Status unknown";
        break;
      }
    }

    return message;
  }
}

// Physical constants used to turn a barometric pressure delta into a
// distance. Water is ~800x denser than air, so the same pressure change
// means a much smaller distance underwater than it does above the surface.
const GRAVITY = 9.80665; // m/s^2
const AIR_DENSITY = 1.225; // kg/m^3, sea-level standard atmosphere
const FRESH_WATER_DENSITY = 1000.0; // kg/m^3
const SALT_WATER_DENSITY = 1025.0; // kg/m^3
const METERS_TO_FEET = 3.28084;

const REFERENCE_PRESSURE_STORAGE_KEY = "ReferencePressure";

// Pure conversion from a pressure delta (current pressure minus the
// calibrated surface pressure, in Pa) to a signed depth in meters: positive
// is below the surface (uses water density), negative is above it (uses air
// density). Kept as a standalone function so it can be unit tested directly.
// A single, current-as-possible raw pressure reading, used by LiveDiveTracker
// and DiagnosticPressureTracker for 1 Hz polling. Confirmed empirically (this
// SDK's simulator) that Activity.Info.rawAmbientPressure/ambientPressure are
// null without an active Activity recording -- this SensorHistory query is
// not, and is the same mechanism the app already used for "Calibrate to
// Surface" before this feature existed.
function getCurrentRawPressure() as Number or Float or Null {
  if (
    !(Toybox has :SensorHistory) ||
    !(Toybox.SensorHistory has :getPressureHistory)
  ) {
    return null;
  }

  var pressureIterator = Toybox.SensorHistory.getPressureHistory({
    :period => 1,
    :order => SensorHistory.ORDER_NEWEST_FIRST,
  });
  var sample = pressureIterator.next();
  if (sample == null) {
    return null;
  }
  return sample.data;
}

function depthMetersFromPressureDelta(
  delta as Number or Float,
  waterDensity as Float
) as Float {
  return (
    delta >= 0
      ? delta / (waterDensity * GRAVITY)
      : delta / (AIR_DENSITY * GRAVITY)
  ).toFloat();
}

// Coordinator: owns the three data sources behind the app's four swipeable
// pages and proxies the shared getters to whichever is active. All three
// sources sample/reload continuously for the app's lifetime regardless of
// which page is on screen, so switching pages never shows stale data.
class SimpDepthState {
  enum Mode {
    MODE_LIVE,
    MODE_DIVE_SUMMARY,
    MODE_HISTORY,
    MODE_DIAGNOSTIC,
  }
  private const MODE_COUNT = 4;

  private var _mode as Number = MODE_LIVE;

  // Fetch the system units
  private var _systemUnits as System.UnitsSystem =
    System.getDeviceSettings().elevationUnits;

  // Used for various adjustments depending on the screen resolution
  private var _sizeFactor as Number = Math.floor(
    System.getDeviceSettings().screenWidth / 100
  ).toNumber();

  private var _historySize as Number;

  private var _liveTracker as LiveDiveTracker;
  private var _historySource as HistoryDepthSource;
  private var _diagnostic as DiagnosticPressureTracker;

  function initialize() {
    // Determine the best size of the sensor history/live chart depending on
    // the screen size and resolution
    var historyHours = Math.floor(
      System.getDeviceSettings().screenWidth / 30 - _sizeFactor
    ).toNumber();
    if (historyHours > 6) {
      historyHours = 6;
    }
    self._historySize = historyHours * 30; // 30 data points per hour, every 2 minutes

    self._historySource = new HistoryDepthSource(
      historyHours,
      _historySize,
      _systemUnits
    );
    self._liveTracker = new LiveDiveTracker(_historySize, _systemUnits);
    self._diagnostic = new DiagnosticPressureTracker();
  }

  function getMode() as Number {
    return _mode;
  }

  function nextMode() as Number {
    _mode = (_mode + 1) % MODE_COUNT;
    return _mode;
  }

  function previousMode() as Number {
    _mode = (_mode + MODE_COUNT - 1) % MODE_COUNT;
    return _mode;
  }

  function calibrateToCurrentSurface() as Void {
    _historySource.calibrateToCurrentSurface();
  }

  function updateWaterDensity() as Void {
    _historySource.updateWaterDensity();
    _historySource.load();
    _liveTracker.updateWaterDensity();
  }

  function destroy() as Void {
    _liveTracker.destroy();
    _historySource.destroy();
    _diagnostic.destroy();
  }

  function getSystemUnits() as System.UnitsSystem {
    return _systemUnits;
  }

  function getSizeFactor() as Number {
    return _sizeFactor;
  }

  function getHistorySize() as Number {
    return _historySize;
  }

  // Shared getters used by SimpDepthView/DepthChartDrawable — dispatch to
  // whichever source backs the current page.
  function getStatus() as Status {
    if (_mode == MODE_HISTORY) {
      return _historySource.getStatus();
    } else if (_mode == MODE_DIAGNOSTIC) {
      return _diagnostic.getStatus();
    }
    return _liveTracker.getStatus();
  }

  function getDepth() as Number or Float or Null {
    if (_mode == MODE_HISTORY) {
      return _historySource.getDepth();
    }
    return _liveTracker.getCurrentDepth();
  }

  function getMinimumDepth() as Number or Float or Null {
    if (_mode == MODE_HISTORY) {
      return _historySource.getMinimumDepth();
    }
    return _liveTracker.getChartMinimum();
  }

  function getMaximumDepth() as Number or Float or Null {
    if (_mode == MODE_HISTORY) {
      return _historySource.getMaximumDepth();
    }
    return _liveTracker.getChartMaximum();
  }

  function getDepthHistory() as Lang.Array<Number or Float or Null> {
    if (_mode == MODE_HISTORY) {
      return _historySource.getDepthHistory();
    }
    return _liveTracker.getChartHistory();
  }

  function getPeriodLabel() as String {
    if (_mode == MODE_HISTORY) {
      return _historySource.getPeriodLabel();
    }
    return _liveTracker.getPeriodLabel();
  }

  // Dive-summary-only stats, always tracked live by LiveDiveTracker
  // regardless of which page is on screen.
  function getMaxDepthThisDive() as Number or Float or Null {
    return _liveTracker.getMaxDepthThisDive();
  }

  function getMaxDepthSession() as Number or Float or Null {
    return _liveTracker.getMaxDepthSession();
  }

  function getDiveCount() as Number {
    return _liveTracker.getDiveCount();
  }

  // Diagnostic-only readout, always live regardless of the current page.
  function getCurrentPressure() as Number or Float or Null {
    return _diagnostic.getCurrentPressure();
  }

  function getMaxPressureSeen() as Number or Float or Null {
    return _diagnostic.getMaxPressureSeen();
  }
}
