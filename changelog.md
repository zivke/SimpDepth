# Changelog

## 0.2.2

- Fixed the Live and Diagnostic pages' pressure reading being stuck at a
  couple-minutes cadence instead of 1 Hz, and reporting wildly wrong depth
  when it did update. Confirmed via real salt-water testing that on real
  hardware, outside of an active Activity recording, the barometer is only
  refreshed by the OS every couple of minutes — true regardless of which
  Toybox API reads it, so the self-calibrating surface reference ended up
  built from near-duplicate stale values. The app now keeps a minimal,
  hidden recording running for its own lifetime (never surfaced to the user,
  never saved, nothing synced to Garmin Connect) purely to unlock live
  barometer sampling. History is unaffected — its couple-minutes cadence is
  expected.

## 0.2.1

- Gave SimpDepth its own app id, independent of SimpTemp (the app it was
  originally cloned from). No published listing existed under the old id,
  so this is a clean break — no behavior change for anyone running the app.

## 0.2.0

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
