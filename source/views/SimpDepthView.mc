import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class SimpDepthView extends WatchUi.View {
  private var _simpDepthState as SimpDepthState;

  function initialize(simpDepthState as SimpDepthState) {
    self._simpDepthState = simpDepthState;

    View.initialize();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.MainLayout(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Graphics.Dc) as Void {
    if (_simpDepthState.getStatus().getCode() != Status.DONE) {
      WatchUi.switchToView(
        new SimpDepthInfoView(_simpDepthState as SimpDepthState),
        null,
        WatchUi.SLIDE_IMMEDIATE
      );
    } else {
      drawCurrentTime(dc);
      drawDepthValues(dc);
      drawDepthChart(dc);
    }

    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);
  }

  private function drawCurrentTime(dc as Graphics.Dc) {
    var clockLabel = View.findDrawableById("clockValue") as Text?;
    if (clockLabel != null) {
      var currentTime = System.getClockTime();
      clockLabel.setText(
        currentTime.hour.format("%02d") + ":" + currentTime.min.format("%02d")
      );
    }
  }

  // Draw the current depth/height value plus the shallowest/deepest extremes
  private function drawDepthValues(dc as Graphics.Dc) {
    var unitSuffix =
      _simpDepthState.getSystemUnits() == System.UNIT_STATUTE ? "ft" : "m";

    // Set the depth/height label value. Positive means below the surface
    // (depth), negative means above it (height).
    var currentDepth = _simpDepthState.getDepth();
    var depthLabel = View.findDrawableById("depthValue") as Text?;
    if (depthLabel != null && currentDepth != null) {
      var prefix = currentDepth >= 0 ? "Depth: " : "Height: ";
      depthLabel.setText(
        prefix + currentDepth.abs().format("%.1f") + unitSuffix
      );
    }

    // Set the shallowest/highest value label (least depth reached)
    var minimumDepthLabel =
      View.findDrawableById("minimumDepthValue") as Text?;
    var minimumDepth = _simpDepthState.getMinimumDepth();
    if (minimumDepthLabel != null && minimumDepth != null) {
      var minimumPrefix = minimumDepth >= 0 ? "min depth: " : "max height: ";
      minimumDepthLabel.setText(
        minimumPrefix + minimumDepth.abs().format("%.1f") + unitSuffix
      );
    }

    // Set the deepest value label (most depth reached)
    var maximumDepthLabel =
      View.findDrawableById("maximumDepthValue") as Text?;
    var maximumDepth = _simpDepthState.getMaximumDepth();
    if (maximumDepthLabel != null && maximumDepth != null) {
      var maximumPrefix = maximumDepth >= 0 ? "max depth: " : "min height: ";
      maximumDepthLabel.setText(
        maximumPrefix + maximumDepth.abs().format("%.1f") + unitSuffix
      );
    }
  }

  // Draw the depth chart
  private function drawDepthChart(dc as Graphics.Dc) {
    var depthChartDrawable =
      View.findDrawableById("DepthChart") as DepthChartDrawable?;
    if (depthChartDrawable != null) {
      depthChartDrawable.setSimpDepthState(_simpDepthState);
    }
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}
}
