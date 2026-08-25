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

  // Swipe/page between the four pages: Live -> Dive Stats -> History ->
  // Diagnostic.
  function onNextPage() as Boolean {
    var simpDepthState = getApp().getSimpDepthState();
    if (simpDepthState == null) {
      return true;
    }
    return switchPage(simpDepthState, simpDepthState.nextMode());
  }

  function onPreviousPage() as Boolean {
    var simpDepthState = getApp().getSimpDepthState();
    if (simpDepthState == null) {
      return true;
    }
    return switchPage(simpDepthState, simpDepthState.previousMode());
  }

  private function switchPage(
    simpDepthState as SimpDepthState,
    newMode as Number
  ) as Boolean {
    if (newMode == SimpDepthState.MODE_DIAGNOSTIC) {
      WatchUi.switchToView(
        new SimpDepthDiagnosticView(simpDepthState),
        new SimpDepthDelegate(),
        WatchUi.SLIDE_IMMEDIATE
      );
    } else if (newMode == SimpDepthState.MODE_DIVE_SUMMARY) {
      WatchUi.switchToView(
        new SimpDepthDiveSummaryView(simpDepthState),
        new SimpDepthDelegate(),
        WatchUi.SLIDE_IMMEDIATE
      );
    } else {
      WatchUi.switchToView(
        new SimpDepthView(simpDepthState),
        new SimpDepthDelegate(),
        WatchUi.SLIDE_IMMEDIATE
      );
    }
    return true;
  }
}
