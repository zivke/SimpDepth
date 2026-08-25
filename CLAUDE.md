# SimpDepth

Garmin Connect IQ watch app: shows depth below the water surface, or height
above it, derived from the internal barometric pressure sensor. Four
swipeable pages: Live (1 Hz tracking, self-calibrating, current/min/max
scoped to the visible chart window), Dive Stats (whole-session per-dive max,
session max, dive count — from LiveDiveTracker, not persisted across app
launches), History (long-span low-res chart, calibrates via the Options
menu), and Diagnostic (raw-pressure measurement tool, see README). Only
devices with a barometric altimeter are supported.

This is a depth *estimate* for recreational snorkeling, not a dive computer
— no decompression/no-stop/ascent-rate logic, no depth-triggered alerts.
Keep it that way; see README and the Settings-screen disclaimer.

Everything runs in the devcontainer — SDK, simulator and developer key are
already set up. Never install or generate them.

## Commands

- `make build` / `make release` — compile for `$(DEVICE)` (default `instinct2`)
- `make sim` then `make run` — simulator must be running before `monkeydo`
- `make test` — `monkey-test.jungle` with `--unit-test`
- `make package` — `.iq` for the store; needs `make all-devices` first
- `make dev-device` — download one device's files; `make all-devices` is many GB

## Layout

- `source/` — app code
- `resources/` — base resources, compiled into `Rez.*`
- `resources-round/`, `resources-rectangle/`, `resources-semioctagon-176x176/`,
  `resources-instinct2s/`, `resources-instincte40mm/` — layout overrides layered
  over `resources/` per shape or device. A layout change usually means touching
  several of these, not just one.
- `source-test/` — test-only, reached via `monkey-test.jungle`
- `manifest.xml` — ~90 products. Adding one means editing it, downloading the
  device, and updating the supported-devices list in `README.md`.

## Conventions

- Type checking is Strict — annotate params and returns
- User-visible text goes in the strings resources, never inline
- Never change `manifest.xml`'s `id` — it is the published app's identity
- Update `changelog.md` for anything user-visible
