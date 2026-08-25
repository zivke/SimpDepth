import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Second page: the whole-session dive stats LiveDiveTracker maintains
// (deepest point of the most recent dive, deepest point of the whole
// session, and how many dives have been detected), separate from the Live
// page's chart-window-scoped current/min/max.
class SimpDepthDiveSummaryView extends WatchUi.View {
  private var _simpDepthState as SimpDepthState;

  function initialize(simpDepthState as SimpDepthState) {
    self._simpDepthState = simpDepthState;
    View.initialize();
  }

  function onLayout(dc as Dc) as Void {}
  function onShow() as Void {}
  function onHide() as Void {}

  function onUpdate(dc as Graphics.Dc) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var width = dc.getWidth();
    var height = dc.getHeight();
    var unitSuffix =
      _simpDepthState.getSystemUnits() == System.UNIT_STATUTE ? "ft" : "m";

    dc.drawText(
      width / 2,
      Math.floor(height * 0.12).toNumber(),
      Graphics.FONT_TINY,
      "Dive Stats",
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    var thisDiveText = "No dives yet";
    var maxDepthThisDive = _simpDepthState.getMaxDepthThisDive();
    if (maxDepthThisDive != null) {
      thisDiveText = maxDepthThisDive.abs().format("%.1f") + unitSuffix;
    }
    dc.drawText(
      width / 2,
      Math.floor(height * 0.35).toNumber(),
      Graphics.FONT_MEDIUM,
      thisDiveText,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
    dc.drawText(
      width / 2,
      Math.floor(height * 0.48).toNumber(),
      Graphics.FONT_XTINY,
      "last dive max",
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    var sessionText = "N/A";
    var maxDepthSession = _simpDepthState.getMaxDepthSession();
    if (maxDepthSession != null) {
      sessionText = maxDepthSession.abs().format("%.1f") + unitSuffix;
    }
    dc.drawText(
      width / 2,
      Math.floor(height * 0.68).toNumber(),
      Graphics.FONT_SMALL,
      "session max: " + sessionText,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    dc.drawText(
      width / 2,
      Math.floor(height * 0.85).toNumber(),
      Graphics.FONT_SMALL,
      "dives: " + _simpDepthState.getDiveCount(),
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
  }
}
