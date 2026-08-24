import Toybox.Application;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

class SimpDepthMenu2Delegate extends WatchUi.Menu2InputDelegate {
  function initialize() {
    Menu2InputDelegate.initialize();
  }

  function onSelect(item as MenuItem) {
    if (item instanceof ToggleMenuItem && item.getId() == :ShowMinMaxLines) {
      try {
        Application.Properties.setValue("ShowMinMaxLines", item.isEnabled());
      } catch (exception) {
        // DO NOTHING - the property cannot be saved
      }
      return;
    }

    if (item instanceof ToggleMenuItem && item.getId() == :SaltWater) {
      try {
        Application.Properties.setValue("SaltWater", item.isEnabled());
      } catch (exception) {
        // DO NOTHING - the property cannot be saved
      }

      var simpDepthState = getApp().getSimpDepthState();
      if (simpDepthState != null) {
        simpDepthState.updateWaterDensity();
        simpDepthState.load();
      }
      return;
    }

    if (item.getId() == :CalibrateToSurface) {
      var simpDepthState = getApp().getSimpDepthState();
      if (simpDepthState == null) {
        return;
      }

      if (
        !(Toybox has :SensorHistory) ||
        !(Toybox.SensorHistory has :getPressureHistory)
      ) {
        return;
      }

      var pressureIterator = Toybox.SensorHistory.getPressureHistory({
        :period => 1,
        :order => SensorHistory.ORDER_NEWEST_FIRST,
      });
      var sensorSample = pressureIterator.next();
      if (sensorSample != null) {
        simpDepthState.calibrateToSurface(sensorSample.data);
      }
    }
  }
}
