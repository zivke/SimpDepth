import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;

(:glance)
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
(:glance)
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

(:glance)
class SimpDepthState {
  // Fetch the system units
  private var _systemUnits as System.UnitsSystem =
    System.getDeviceSettings().elevationUnits;

  // Used for various adjustments depending on the screen resolution
  private var _sizeFactor as Number = Math.floor(
    System.getDeviceSettings().screenWidth / 100
  ).toNumber();

  // Determine the best size of the sensor history depending on the screen size and resolution
  private var _historyHours as Number;
  private var _historySize as Number;
  private var _depthHistory as Lang.Array<Number or Float or Null>;
  private var _depth as Number or Float or Null; // Current depth/height value
  private var _minimumDepth as Number or Float or Null; // Shallowest/highest value (least depth)
  private var _maximumDepth as Number or Float or Null; // Deepest value

  // The pressure reading, in Pascals, that represents the water surface
  // (depth/height == 0). Null until the first calibration happens.
  private var _referencePressure as Number or Float or Null;

  // Water density to use for the underwater side of the conversion
  private var _waterDensity as Float = FRESH_WATER_DENSITY;

  private var _timer as Timer.Timer;

  private var _status as Status;

  // Time to wait before retrying to load the pressure data
  private var _retryDelay as Number = 2000;
  private var _retryCount as Number = 0;

  function initialize() {
    self._historyHours = Math.floor(
      System.getDeviceSettings().screenWidth / 30 - _sizeFactor
    ).toNumber();
    if (self._historyHours > 6) {
      self._historyHours = 6;
    }
    self._historySize = self._historyHours * 30; // 30 data points per hour, every 2 minutes
    self._depthHistory = new Lang.Array<Number or Float or Null>[_historySize];

    self._status = new Status();
    self._timer = new Timer.Timer();

    self._referencePressure = Application.Storage.getValue(
      REFERENCE_PRESSURE_STORAGE_KEY
    ) as Number or Float or Null;

    updateWaterDensity();

    // Check device for SensorHistory compatibility
    if (
      !(Toybox has :SensorHistory) ||
      !(Toybox.SensorHistory has :getPressureHistory)
    ) {
      _status.setCode(Status.UNSUPPORTED);
      return;
    }

    load();
  }

  function updateWaterDensity() as Void {
    var saltWater = Application.Properties.getValue("SaltWater") as Boolean?;
    self._waterDensity = saltWater ? SALT_WATER_DENSITY : FRESH_WATER_DENSITY;
  }

  // Store the given raw pressure reading (or the latest known one, if none
  // is given) as the new surface reference and reload.
  function calibrateToSurface(
    pressure as Number or Float or Null
  ) as Void {
    if (pressure == null) {
      return;
    }

    self._referencePressure = pressure;
    Application.Storage.setValue(REFERENCE_PRESSURE_STORAGE_KEY, pressure);
    load();
  }

  function load() as Void {
    if (_status.getCode() == Status.INITIALIZING) {
      _status.setCode(Status.LOADING);
    } else if (_status.getCode() == Status.LOADING) {
      return;
    } else if (_status.getCode() == Status.DONE) {
      _retryCount = 0;
      _status.setCode(Status.LOADING);
    } else {
      _retryCount += 1;
      if (_retryCount >= 4) {
        // Fatal error - stop everything and keep the last error
        _timer.stop();
        WatchUi.requestUpdate();
        return;
      }
    }

    reset();

    // Get the pressure history iterator
    var pressureIterator = Toybox.SensorHistory.getPressureHistory({
      :period => new Time.Duration(
        Time.Gregorian.SECONDS_PER_HOUR * _historyHours
      ),
      :order => SensorHistory.ORDER_NEWEST_FIRST,
    });

    // Get the pressure indexes for the depth history array
    var startTime = pressureIterator.getOldestSampleTime();
    var endTime = pressureIterator.getNewestSampleTime();
    if (startTime == null || endTime == null) {
      _status.setCode(Status.NO_START_END_TIME);
      _timer.stop();
      _timer.start(method(:load), _retryDelay, true);
      return;
    }

    // It has happened sometimes that the time difference between the first and last sample
    // is more than the expected history size. In this case, we need to adjust the index.
    var totalTimeDiff = endTime.subtract(startTime);
    var index_correction =
      _historySize - 1 - Math.floor(totalTimeDiff.value() / 120).toNumber();

    var sensorSample = pressureIterator.next();
    if (sensorSample == null) {
      _status.setCode(Status.INVALID_DATA);
      _timer.stop();
      _timer.start(method(:load), _retryDelay, true);
      return;
    }

    // Auto-calibrate on the very first ever reading, so the widget works
    // without any setup (assumes it's launched at/near the surface).
    if (_referencePressure == null) {
      calibrateToSurfaceSilently(sensorSample.data);
    }

    self._depth = convertPressureToDepth(sensorSample.data);

    while (sensorSample != null) {
      if (sensorSample.data != null) {
        var timeDiff = sensorSample.when.subtract(startTime);
        var index =
          Math.floor(timeDiff.value() / 120).toNumber() + index_correction; // Every 2 minutes
        if (index >= 0 && index < _historySize) {
          _depthHistory[index] = convertPressureToDepth(sensorSample.data);
        } else {
          System.println(
            "Error: Pressure reading time out of range (index: " +
              index +
              ")"
          );
        }
      }

      sensorSample = pressureIterator.next();
    }

    // depth() is monotonically increasing in pressure (higher pressure =
    // deeper), so the SDK's pressure getMin()/getMax() map directly to our
    // minimum (shallowest/highest point) and maximum (deepest point) depth.
    self._minimumDepth = convertPressureToDepth(pressureIterator.getMin());
    self._maximumDepth = convertPressureToDepth(pressureIterator.getMax());

    if (_minimumDepth == null || _maximumDepth == null) {
      _status.setCode(Status.NO_MIN_MAX_PRESSURE);
      _timer.stop();
      _timer.start(method(:load), _retryDelay, true);
      return;
    }

    _status.setCode(Status.DONE);
    _timer.stop();
    _timer.start(method(:load), 30000, true); // Reload the pressure data every 30 seconds

    // WatchUi.requestUpdate(); gets called by _status.setCode()
  }

  private function calibrateToSurfaceSilently(
    pressure as Number or Float or Null
  ) as Void {
    if (pressure == null) {
      return;
    }

    self._referencePressure = pressure;
    Application.Storage.setValue(REFERENCE_PRESSURE_STORAGE_KEY, pressure);
  }

  private function reset() as Void {
    _depthHistory = new Lang.Array<Number or Float or Null>[_historySize];
    _depth = null;
    _minimumDepth = null;
    _maximumDepth = null;
  }

  // Converts a raw barometric pressure reading (Pa) into a signed distance
  // (m or ft, depending on system units) from the calibrated water surface:
  // positive means below the surface (depth), negative means above it
  // (height).
  private function convertPressureToDepth(
    pressure as Number or Float or Null
  ) as Number or Float or Null {
    if (pressure == null || _referencePressure == null) {
      return null;
    }

    var depthMeters = depthMetersFromPressureDelta(
      pressure - _referencePressure,
      _waterDensity
    );

    if (_systemUnits == System.UNIT_STATUTE) {
      return depthMeters * METERS_TO_FEET;
    }

    return depthMeters;
  }

  function destroy() as Void {
    _timer.stop();
  }

  function getSystemUnits() as System.UnitsSystem {
    return _systemUnits;
  }

  function getSizeFactor() as Number {
    return _sizeFactor;
  }

  function getHistoryHours() as Number {
    return _historyHours;
  }

  function getHistorySize() as Number {
    return _historySize;
  }

  function getDepthHistory() as Lang.Array<Number or Float or Null> {
    return _depthHistory;
  }

  function getDepth() as Number or Float or Null {
    return _depth;
  }

  function getMinimumDepth() as Number or Float or Null {
    return _minimumDepth;
  }

  function getMaximumDepth() as Number or Float or Null {
    return _maximumDepth;
  }

  function getReferencePressure() as Number or Float or Null {
    return _referencePressure;
  }

  function getStatus() as Status {
    return _status;
  }
}
