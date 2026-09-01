import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Lang;

// Starts a minimal FIT recording session for the app's whole lifetime, purely
// to unlock live barometer sampling -- confirmed via real salt-water testing
// that outside of an active Activity recording, the OS only refreshes the
// pressure sensor every couple of minutes, throttling SensorHistory and
// Sensor.Info.pressure identically. That's a hardware/OS power-saving
// behavior, not an artifact of either API. Activity.Info.rawAmbientPressure
// only updates live during a recording, so this session exists to make that
// true, without exposing anything session-like to the user: no name/sport
// shown anywhere, never saved -- stop()+discard() on app exit means no FIT
// file is written and nothing appears in Garmin Connect.
class HiddenRecordingSession {
  private var _session as ActivityRecording.Session?;

  function initialize() {
    if (!(Toybox has :ActivityRecording)) {
      return;
    }
    var session = ActivityRecording.createSession({
      :name => "SimpDepth",
      :sport => Activity.SPORT_GENERIC,
    });
    session.start();
    _session = session;
  }

  function destroy() as Void {
    var session = _session;
    if (session == null) {
      return;
    }
    if (session.isRecording()) {
      session.stop();
    }
    session.discard();
    _session = null;
  }
}
