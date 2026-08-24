import Toybox.Lang;
import Toybox.WatchUi;

class SimpDepthDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onMenu() as Boolean {
    var menu = new Rez.Menus.OptionsMenu() as Menu2;
    var showMinMaxLines =
      Application.Properties.getValue("ShowMinMaxLines") as Boolean?;
    if (showMinMaxLines != null) {
      var showMinMaxLinesIndex = menu.findItemById(:ShowMinMaxLines);
      if (showMinMaxLinesIndex >= 0) {
        var item = menu.getItem(showMinMaxLinesIndex);
        if (item != null && item instanceof ToggleMenuItem) {
          (item as ToggleMenuItem).setEnabled(showMinMaxLines);
        }
      }
    }

    var saltWater = Application.Properties.getValue("SaltWater") as Boolean?;
    if (saltWater != null) {
      var saltWaterIndex = menu.findItemById(:SaltWater);
      if (saltWaterIndex >= 0) {
        var item = menu.getItem(saltWaterIndex);
        if (item != null && item instanceof ToggleMenuItem) {
          (item as ToggleMenuItem).setEnabled(saltWater);
        }
      }
    }

    WatchUi.pushView(
      menu,
      new SimpDepthMenu2Delegate(),
      WatchUi.SLIDE_IMMEDIATE
    );
    return true;
  }
}
