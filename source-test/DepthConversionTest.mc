import Toybox.Lang;
import Toybox.Test;

const TEST_EPSILON = 0.01;

function assertApprox(
  logger as Logger,
  actual as Float,
  expected as Float
) as Void {
  var diff = actual - expected;
  if (diff < 0) {
    diff = -diff;
  }
  logger.debug("expected " + expected + ", got " + actual);
  Test.assert(diff < TEST_EPSILON);
}

// At the surface, there's no pressure delta, so depth should be exactly 0.
(:test)
function depthAtSurfaceIsZero(logger as Logger) as Boolean {
  assertApprox(
    logger,
    depthMetersFromPressureDelta(0, FRESH_WATER_DENSITY),
    0.0
  );
  return true;
}

// A rise in pressure of waterDensity * GRAVITY Pascals corresponds to
// exactly 1 meter of fresh water.
(:test)
function oneMeterOfFreshWaterDepth(logger as Logger) as Boolean {
  var delta = FRESH_WATER_DENSITY * GRAVITY;
  assertApprox(
    logger,
    depthMetersFromPressureDelta(delta, FRESH_WATER_DENSITY),
    1.0
  );
  return true;
}

// Salt water is denser, so the same depth needs a larger pressure delta -
// equivalently, the same delta yields a shallower reading in salt water.
(:test)
function saltWaterIsDenserThanFreshWater(logger as Logger) as Boolean {
  var delta = 10000.0;
  var freshDepth = depthMetersFromPressureDelta(delta, FRESH_WATER_DENSITY);
  var saltDepth = depthMetersFromPressureDelta(delta, SALT_WATER_DENSITY);
  logger.debug("fresh: " + freshDepth + ", salt: " + saltDepth);
  Test.assert(saltDepth < freshDepth);
  Test.assert(saltDepth > 0);
  return true;
}

// A drop in pressure of AIR_DENSITY * GRAVITY Pascals corresponds to
// exactly 1 meter *above* the surface, i.e. -1 meter of depth.
(:test)
function oneMeterAboveSurfaceIsNegativeDepth(logger as Logger) as Boolean {
  var delta = -1 * AIR_DENSITY * GRAVITY;
  assertApprox(
    logger,
    depthMetersFromPressureDelta(delta, FRESH_WATER_DENSITY),
    -1.0
  );
  return true;
}

// Air is far less dense than water, so the same magnitude pressure delta
// produces a much larger distance above the surface than below it.
(:test)
function airSideIsMuchMoreSensitiveThanWaterSide(logger as Logger) as Boolean {
  var below = depthMetersFromPressureDelta(1000, FRESH_WATER_DENSITY);
  var above = depthMetersFromPressureDelta(-1000, FRESH_WATER_DENSITY);
  logger.debug("below: " + below + ", above: " + above);
  Test.assert(below > 0);
  Test.assert(above < 0);
  Test.assert(above.abs() > below.abs() * 10);
  return true;
}
