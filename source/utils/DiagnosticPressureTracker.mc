import Toybox.Lang;
import Toybox.Timer;

// Deliberately minimal: current raw pressure and the max seen since the app
// was opened, so a device's barometric saturation ceiling can be read
// straight off the watch while descending in steps, no sync required. See
// README's water-test protocol. This is a measurement instrument, not a UI
// -- no chart, no depth math, no smoothing. Pressure comes from the shared
// getCurrentRawPressure() helper (see SimpDepthState.mc).
class DiagnosticPressureTracker {
  private var _currentPressure as Number or Float or Null;
  private var _maxPressureSeen as Number or Float or Null;
  private var _status as Status;
  private var _timer as Timer.Timer;

  function initialize() {
    _status = new Status();
    _timer = new Timer.Timer();
    sample(); // first reading right away, don't make the user wait 1s
    _timer.start(method(:sample), 1000, true);
  }

  function sample() as Void {
    var pressure = getCurrentRawPressure();
    if (pressure == null) {
      return;
    }

    _currentPressure = pressure;
    if (
      _maxPressureSeen == null ||
      pressure > (_maxPressureSeen as Number or Float)
    ) {
      _maxPressureSeen = pressure;
    }

    _status.setCode(Status.DONE);
  }

  function destroy() as Void {
    _timer.stop();
  }

  function getCurrentPressure() as Number or Float or Null {
    return _currentPressure;
  }

  function getMaxPressureSeen() as Number or Float or Null {
    return _maxPressureSeen;
  }

  function getStatus() as Status {
    return _status;
  }
}
