import Toybox.Lang;
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
      }
      return;
    }

    if (item.getId() == :CalibrateToSurface) {
      var simpDepthState = getApp().getSimpDepthState();
      if (simpDepthState != null) {
        simpDepthState.calibrateToCurrentSurface();
      }
    }
  }
}
