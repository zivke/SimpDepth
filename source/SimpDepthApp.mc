import Toybox.Application;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

(:glance)
class SimpDepthApp extends Application.AppBase {
  private var _glanceDepthString as String?;
  private var _simpDepthState as SimpDepthState?;

  function initialize() {
    AppBase.initialize();

    if (
      Toybox has :SensorHistory &&
      Toybox.SensorHistory has :getPressureHistory
    ) {
      // Get the pressure history iterator
      var pressureIterator = Toybox.SensorHistory.getPressureHistory({
        :period => 1,
        :order => SensorHistory.ORDER_NEWEST_FIRST,
      });

      // Get the current pressure reading first
      var sensorSample = pressureIterator.next();
      var referencePressure = Application.Storage.getValue(
        REFERENCE_PRESSURE_STORAGE_KEY
      ) as Number or Float or Null;
      if (sensorSample != null && referencePressure != null) {
        self._glanceDepthString = getDepthString(
          sensorSample.data,
          referencePressure
        );
      }
    }
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    self._simpDepthState = new SimpDepthState();
  }

  function getSimpDepthState() as SimpDepthState? {
    return _simpDepthState;
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    if (_simpDepthState != null) {
      _simpDepthState.destroy();
    }
  }

  (:glance)
  function getGlanceView() as [GlanceView] or
    [GlanceView, GlanceViewDelegate] or
    Null {
    return [new SimpDepthGlanceView(_glanceDepthString)];
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (_simpDepthState.getStatus().getCode() == Status.DONE) {
      return [
        new SimpDepthView(_simpDepthState as SimpDepthState),
        new SimpDepthDelegate(),
      ];
    } else {
      return [new SimpDepthInfoView(_simpDepthState as SimpDepthState)];
    }
  }

  private function getDepthString(
    pressure as Number or Float or Null,
    referencePressure as Number or Float or Null
  ) as String? {
    if (pressure == null || referencePressure == null) {
      return null;
    }

    var waterDensity = Application.Properties.getValue("SaltWater")
      ? SALT_WATER_DENSITY
      : FRESH_WATER_DENSITY;

    var delta = pressure - referencePressure;
    var depthMeters =
      delta >= 0
        ? delta / (waterDensity * GRAVITY)
        : delta / (AIR_DENSITY * GRAVITY);

    var depth = depthMeters;
    var unitSuffix = "m";
    if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) {
      depth = depthMeters * METERS_TO_FEET;
      unitSuffix = "ft";
    }

    var label = depth >= 0 ? "Depth: " : "Height: ";
    return label + depth.abs().format("%.1f").toString() + unitSuffix;
  }
}

function getApp() as SimpDepthApp {
  return Application.getApp() as SimpDepthApp;
}
