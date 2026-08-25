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

  // Draw the current depth/height value (the black accent circle on round
  // layouts) plus the shallowest/deepest extremes, in real time. Same
  // meaning in both modes -- only what backs "current"/"min"/"max" differs:
  // History is the period's SensorHistory data, Live is the current live
  // reading and the visible chart window's extremes.
  private function drawDepthValues(dc as Graphics.Dc) {
    var unitSuffix =
      _simpDepthState.getSystemUnits() == System.UNIT_STATUTE ? "ft" : "m";

    // Positive means below the surface (depth), negative means above it
    // (height).
    var depthLabel = View.findDrawableById("depthValue") as Text?;
    if (depthLabel != null) {
      depthLabel.setText(formatDepth(_simpDepthState.getDepth(), unitSuffix));
    }

    var minimumDepthLabel =
      View.findDrawableById("minimumDepthValue") as Text?;
    if (minimumDepthLabel != null) {
      minimumDepthLabel.setText(
        "min: " + formatDepth(_simpDepthState.getMinimumDepth(), unitSuffix)
      );
    }

    var maximumDepthLabel =
      View.findDrawableById("maximumDepthValue") as Text?;
    if (maximumDepthLabel != null) {
      maximumDepthLabel.setText(
        "max: " + formatDepth(_simpDepthState.getMaximumDepth(), unitSuffix)
      );
    }
  }

  private function formatDepth(
    depth as Number or Float or Null,
    unitSuffix as String
  ) as String {
    if (depth == null) {
      return "N/A";
    }
    return depth.abs().format("%.1f") + unitSuffix;
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
