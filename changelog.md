# Changelog

## Unreleased

- Converted from a widget to a watch app so it no longer gets closed by the
  widget loop mid-session.
- Added a Live page: 1 Hz depth tracking with a continuously self-calibrating
  surface reference (no manual calibration needed) and a chart. Reads the
  sensor's raw, unsmoothed pressure directly, fixing inaccurate readings
  during fast descents.
- Added a Dive Stats page: most recent dive's max depth, session max depth,
  and dive count, tracked continuously for the running session (not saved
  between app launches).
- Added a Diagnostic page for measuring a device's barometric range in real
  water (see README); readings beyond that range now show clearly as
  "beyond range" instead of a misleading number.
- Kept the existing long-span History page (hours of low-resolution data)
  as a separate swipeable page alongside Live, Dive Stats, and Diagnostic.
- Removed the Glance view (not available to watch apps).
- Added a not-a-dive-instrument disclaimer to the app description and
  Settings screen.

## 0.1.0

- Initial release: a widget that shows how far below the water surface you
  are (depth) or how far above it you are (height), calculated from the
  internal barometric pressure sensor. Includes a history chart,
  shallowest/deepest markers for the period, a "Calibrate to Surface" menu
  action, and a "Salt water" setting to account for the higher density of
  salt water when converting pressure to depth.
