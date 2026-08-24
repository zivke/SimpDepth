import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Padding, in display units (m or ft), added around the data range so the
// surface line and the extremes aren't drawn flush against the chart edges.
const CHART_PADDING = 1;

// Vertical gap, in pixels, between a data point's actual position and the
// min/max marker triangle that points at it.
const CHART_MARKER_GAP = 7;

class DepthChartDrawable extends WatchUi.Drawable {
  private var _simpDepthState as SimpDepthState?;
  private var _foregroundColor as Number;
  private var _backgroundColor as Number;

  function setSimpDepthState(simpDepthState as SimpDepthState) {
    self._simpDepthState = simpDepthState;
  }

  function initialize(params as Dictionary?) {
    Drawable.initialize(params);

    var foregroundColor = params.get(:color) as Number?;
    self._foregroundColor = foregroundColor
      ? foregroundColor
      : Graphics.COLOR_BLACK;

    var backgroundColor = params.get(:background) as Number?;
    self._backgroundColor = backgroundColor
      ? backgroundColor
      : Graphics.COLOR_WHITE;
  }

  function draw(dc as Dc) {
    var minimumDepth = _simpDepthState.getMinimumDepth();
    var maximumDepth = _simpDepthState.getMaximumDepth();

    // If no valid data, skip drawing the chart
    if (minimumDepth == null || maximumDepth == null) {
      return;
    }

    // Automatically determine the y location of the drawable if non provided
    if (locY == 0) {
      locY = Math.floor(dc.getHeight() * 0.3).toNumber();
    }

    // Automatically determine the height of the drawable if non provided
    if (height == 0) {
      height = Math.floor(dc.getHeight() * 0.5).toNumber();
    }

    var showMinMaxLines =
      Application.Properties.getValue("ShowMinMaxLines") as Boolean?;

    var chartWidth = _simpDepthState.getHistorySize(); // Chart width
    var chartHeight = (height - 20) as Number; // Chart height
    var chartX = Math.floor((dc.getWidth() - chartWidth) / 2).toNumber(); // X position of the chart
    var chartY = locY as Number; // Y position of the chart

    // Adjust the range to always include the surface (0), so the surface
    // line is always visible, and pad it for a bit of visual headroom.
    var rangeMinimum = minimumDepth < 0 ? minimumDepth : 0;
    var rangeMaximum = maximumDepth > 0 ? maximumDepth : 0;
    var chartMinimum = Math.floor(rangeMinimum).toNumber() - CHART_PADDING;
    var chartMaximum = Math.ceil(rangeMaximum).toNumber() + CHART_PADDING;

    // Draw chart frame (FOR DEBUGGING PURPOSES)
    // dc.drawRectangle(chartX, chartY, chartWidth, chartHeight);

    // Vertical scale. Note the y axis is intentionally flipped relative to a
    // typical chart: a larger (deeper) value must be drawn *lower* on
    // screen, and a smaller (higher/above-surface) value *higher* on
    // screen, to match the physical orientation of being underwater.
    var yScale = chartHeight.toFloat() / (chartMaximum - chartMinimum);
    var zeroY = Math.ceil(chartY + (0 - chartMinimum) * yScale).toNumber();

    // Set colors
    dc.setColor(_foregroundColor, _backgroundColor);

    // Draw the surface line
    dc.drawLine(chartX, zeroY, chartX + chartWidth, zeroY);

    // Draw chart bars, extending from the surface line down (depth) or up
    // (height) to each sample's value
    for (var i = 0; i < _simpDepthState.getHistorySize(); i++) {
      var depth = _simpDepthState.getDepthHistory()[i];
      if (depth != null) {
        var x = chartX + i;
        var y = Math.ceil(chartY + (depth - chartMinimum) * yScale).toNumber();
        dc.drawLine(x, zeroY, x, y);
      }
    }

    // Draw hour marks
    dc.setColor(_backgroundColor, Graphics.COLOR_TRANSPARENT); // Inverted color
    // 30 measurements per hour = one line every 30 values
    for (var i = chartX + 30; i < chartX + chartWidth; i += 30) {
      dc.drawLine(i, chartY + chartHeight, i, chartY + chartHeight - 4);
    }

    var totalChartTimeText =
      "Last " + _simpDepthState.getHistoryHours() + " hours";

    dc.setColor(_foregroundColor, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      chartX + chartWidth / 2,
      chartY + chartHeight + _simpDepthState.getSizeFactor() - 2,
      Graphics.FONT_XTINY,
      totalChartTimeText,
      Graphics.TEXT_JUSTIFY_CENTER
    );

    // Draw the marker for the deepest point (largest depth value), pointing
    // up at its bar tip from below
    for (var i = 0; i < _simpDepthState.getHistorySize(); i++) {
      var depth = _simpDepthState.getDepthHistory()[i];
      if (depth != null && depth == maximumDepth) {
        var x = chartX + i;
        var tipY = Math.ceil(
          chartY + (depth - chartMinimum) * yScale
        ).toNumber();
        drawUpwardTriangle(dc, x, tipY + CHART_MARKER_GAP);

        if (showMinMaxLines) {
          drawHorizontalDottedLine(
            dc,
            chartX,
            chartX + chartWidth,
            tipY,
            Graphics.COLOR_WHITE
          );
        }
        break;
      }
    }

    // Draw the marker for the shallowest/highest point (smallest depth
    // value), pointing down at its bar tip from above
    for (var i = 0; i < _simpDepthState.getHistorySize(); i++) {
      var depth = _simpDepthState.getDepthHistory()[i];
      if (depth != null && depth == minimumDepth) {
        var x = chartX + i;
        var tipY = Math.ceil(
          chartY + (depth - chartMinimum) * yScale
        ).toNumber();
        drawDownwardTriangle(dc, x, tipY - CHART_MARKER_GAP);

        if (showMinMaxLines) {
          drawHorizontalDottedLine(
            dc,
            chartX,
            chartX + chartWidth,
            tipY,
            Graphics.COLOR_BLACK
          );
        }
        break;
      }
    }
  }

  // Draw a triangle pointing up (used to flag the deepest point, sitting
  // below its bar tip)
  private function drawUpwardTriangle(
    dc as Graphics.Dc,
    pointX as Number,
    pointY as Number
  ) {
    // Create the polygon points array
    var points = [
      [pointX, pointY],
      [pointX + 4, pointY + 4],
      [pointX - 4, pointY + 4],
    ];

    // Draw the triangle
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(points);

    // Draw the triangle outline (so it is visible if it goes outside of the chart)
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(pointX, pointY - 1, pointX + 5, pointY + 4);
    dc.drawLine(pointX, pointY - 1, pointX - 5, pointY + 4);
    dc.drawLine(pointX + 5, pointY + 4, pointX - 5, pointY + 4);
  }

  // Draw a triangle pointing down (used to flag the shallowest/highest
  // point, sitting above its bar tip)
  private function drawDownwardTriangle(
    dc as Graphics.Dc,
    pointX as Number,
    pointY as Number
  ) {
    // Create the polygon points array
    var points = [
      [pointX, pointY],
      [pointX + 4, pointY - 4],
      [pointX - 4, pointY - 4],
    ];

    // Draw the triangle
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(points);
  }

  private function drawHorizontalDottedLine(
    dc as Dc,
    startX as Number,
    endX as Number,
    y as Number,
    color as Number
  ) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    for (var i = startX; i < endX; i += 2) {
      dc.drawPoint(i, y);
    }
  }
}
