import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Deliberately minimal third page: raw pressure only, no depth math, no
// chart -- a measurement instrument for finding a device's barometric
// saturation ceiling in real water, not a UI. See README's water-test
// protocol for how to use it and what to do with the result.
class SimpDepthDiagnosticView extends WatchUi.View {
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

    dc.drawText(
      width / 2,
      Math.floor(height * 0.15).toNumber(),
      Graphics.FONT_TINY,
      "Diagnostic",
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    var currentText = "-- Pa";
    var currentPressure = _simpDepthState.getCurrentPressure();
    if (currentPressure != null) {
      currentText = currentPressure.format("%.0f") + " Pa";
    }
    dc.drawText(
      width / 2,
      Math.floor(height * 0.45).toNumber(),
      Graphics.FONT_NUMBER_MEDIUM,
      currentText,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    var maxText = "N/A";
    var maxPressureSeen = _simpDepthState.getMaxPressureSeen();
    if (maxPressureSeen != null) {
      maxText = maxPressureSeen.format("%.0f") + " Pa";
    }
    dc.drawText(
      width / 2,
      Math.floor(height * 0.7).toNumber(),
      Graphics.FONT_SMALL,
      "max: " + maxText,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
  }
}
