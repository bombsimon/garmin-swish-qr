import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

class swishQRApp extends Application.AppBase {
    private var _sw as swishQRView;

    function initialize() {
        _sw = new swishQRView(new swishQR());

        AppBase.initialize();
    }

    function onSettingsChanged() {
        _sw.onSettingsChanged();
    }

    function getGlanceView() {
        return [new swishQRGlance()];
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [_sw];
    }
}

function getApp() as swishQRApp {
    return Application.getApp() as swishQRApp;
}
