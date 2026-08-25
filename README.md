# SimpDepth
A simple minimalistic app for Garmin watches that estimates recreational
snorkeling depth from the internal barometric sensor. **It is not a dive
computer** — it has no decompression, no-stop time, or ascent-rate logic,
and must never be used for scuba, freediving, or any decompression-related
decision.

Four swipeable pages:
- **Live** — 1 Hz depth tracking for the current session, with a
  continuously self-calibrating surface reference (no manual calibration
  needed) and a chart. Current depth plus the min/max shown are scoped to
  what's currently on the chart (the last couple of minutes), not the
  whole session.
- **Dive Stats** — the whole-session numbers: the most recent dive's max
  depth, the session's max depth, and how many dives have been detected.
  Resets when the app is closed; nothing here is saved between sessions.
- **History** — a longer, lower-resolution chart (several hours) backed by
  the watch's own stored pressure history, with the shallowest/deepest
  points reached over that period. Calibrate its "surface" reference from
  the Options menu ("Calibrate to Surface") right before getting in the
  water; it also auto-calibrates itself the first time the app is opened.
- **Diagnostic** — a measurement tool, not something you need day-to-day.
  Garmin's barometric sensors saturate or get clamped by firmware somewhere
  past shallow-water pressure, and where that happens is undocumented and
  device-specific. This page shows the current raw pressure (Pa) and the
  max seen since the app was opened, so you can find that ceiling yourself:
  start the app at the surface, descend in ~0.5 m increments holding each
  for a few seconds, and watch for the value to stop climbing with depth —
  that pressure is the ceiling for your device. The Live page's
  `CEILING_PA` constant (`source/utils/LiveDiveTracker.mc`) ships with an
  unverified placeholder and should be updated with your measured value.

The Options menu also has a "Salt water" setting, to account for the higher
density of salt water when converting pressure to depth.

# Supported devices
- Approach® S70 42mm
- Approach® S70 47mm
- Captain Marvel
- D2™ Air
- D2™ Air X10
- D2™ Mach 1
- D2™ Mach 2
- D2™ Mach 2 Pro
- Darth Vader™
- Descent™ G1 / G1 Solar
- Descent™ G2
- Descent™ Mk2 / Descent™ Mk2i
- Descent™ Mk2 S
- Descent™ Mk3 43mm / Mk3i 43mm
- Descent™ Mk3i 51mm
- Enduro™
- Enduro™ 3
- epix™ (Gen 2) / quatix® 7 Sapphire
- epix™ Pro (Gen 2) 42mm
- epix™ Pro (Gen 2) 47mm / quatix® 7 Pro
- epix™ Pro (Gen 2) 51mm / D2™ Mach 1 Pro / tactix® 7 – AMOLED Edition
- fēnix® 5 Plus
- fēnix® 5S Plus
- fēnix® 5X Plus
- fēnix® 6 / 6 Solar / 6 Dual Power
- fēnix® 6 Pro / 6 Sapphire / 6 Pro Solar / 6 Pro Dual Power / quatix® 6
- fēnix® 6S / 6S Solar / 6S Dual Power
- fēnix® 6S Pro / 6S Sapphire / 6S Pro Solar / 6S Pro Dual Power
- fēnix® 6X Pro / 6X Sapphire / 6X Pro Solar / tactix® Delta Sapphire / Delta Solar / Delta Solar - Ballistics Edition / quatix® 6X / 6X Solar / 6X Dual Power
- fēnix® 7 / quatix® 7
- fēnix® 7 Pro
- fēnix® 7 Pro - Solar Edition (no Wi-Fi)
- fēnix® 7S
- fēnix® 7S Pro
- fēnix® 7X / tactix® 7 / quatix® 7X Solar / Enduro™ 2
- fēnix® 7X Pro
- fēnix® 7X Pro - Solar Edition (no Wi-Fi)
- fēnix® 8 43mm
- fēnix® 8 47mm / 51mm
- fēnix® 8 Pro 47mm / 51mm / MicroLED / quatix® 8 Pro 47mm / 51mm
- fēnix® 8 Solar 47mm
- fēnix® 8 Solar 51mm
- fēnix® E
- First Avenger
- Forerunner® 165
- Forerunner® 165 Music
- Forerunner® 255
- Forerunner® 255 Music
- Forerunner® 255s
- Forerunner® 255s Music
- Forerunner® 265
- Forerunner® 265s
- Forerunner® 570 42mm
- Forerunner® 570 47mm
- Forerunner® 645 Music
- Forerunner® 745
- Forerunner® 945
- Forerunner® 945 LTE
- Forerunner® 955 / Solar
- Forerunner® 965
- Forerunner® 970
- Instinct® 2 / Solar / Dual Power / dēzl Edition
- Instinct® 2S / Solar / Dual Power
- Instinct® 2X Solar
- Instinct® 3 AMOLED 45mm
- Instinct® 3 AMOLED 50mm
- Instinct® 3 Solar 45mm / 50mm
- Instinct® Crossover
- Instinct® Crossover AMOLED
- Instinct® E 40mm
- Instinct® E 45mm
- MARQ® (Gen 2) Athlete / Adventurer / Captain / Golfer / Carbon Edition / Commander - Carbon Edition
- MARQ® (Gen 2) Aviator
- MARQ® Adventurer
- MARQ® Athlete
- MARQ® Aviator
- MARQ® Captain / MARQ® Captain: American Magic Edition
- MARQ® Commander
- MARQ® Driver
- MARQ® Expedition
- MARQ® Golfer
- Rey™
- Venu®
- Venu® 2
- Venu® 2 Plus
- Venu® 2S
- Venu® 3
- Venu® 3S
- Venu® 4 41mm
- Venu® 4 45mm / D2™ Air X15
- Venu® Mercedes-Benz® Collection
- Venu® X1
- vívoactive® 3 Music
- vívoactive® 4
- vívoactive® 4S

# Donations
If you have found this software to be useful, please consider donating to one of the following:
- Patreon http://patreon.com/zivke
- PayPal https://paypal.me/zivke85
- SOL DnoF5EHbbs75y7fhDBkhQwhugHz22bRLmF7ytBE4R1Hq
- ETH 0x2668f3aFEEd471A813a5e38abb72DD2477E393d5
- BTC bc1qs8tsm76p8m4ptzgun9u2jerwmhxln44nj62tt8
