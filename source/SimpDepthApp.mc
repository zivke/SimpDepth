import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SimpDepthApp extends Application.AppBase {
  private var _simpDepthState as SimpDepthState?;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    self._simpDepthState = new SimpDepthState();
  }

  function getSimpDepthState() as SimpDepthState? {
    return _simpDepthState;
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    if (_simpDepthState != null) {
      _simpDepthState.destroy();
    }
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (_simpDepthState.getStatus().getCode() == Status.DONE) {
      return [
        new SimpDepthView(_simpDepthState as SimpDepthState),
        new SimpDepthDelegate(),
      ];
    } else {
      return [new SimpDepthInfoView(_simpDepthState as SimpDepthState)];
    }
  }
}

function getApp() as SimpDepthApp {
  return Application.getApp() as SimpDepthApp;
}
