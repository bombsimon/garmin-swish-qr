import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

// Enabling typechecker makes it not possible to propagate the settings changes
// to the view since it's not available when running in Glance mode.
(:typecheck(false))
class swishQRApp extends Application.AppBase {
    private var _sq as swishQRView?;

    function initialize() {
        AppBase.initialize();
    }

    function onSettingsChanged() {
        if (_sq != null) {
            _sq.onSettingsChanged();
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        _sq = new swishQRView();
        return [_sq];
    }

    // Requires API 3.1.0
    (:glance)
    function getGlanceView() {
        return [new swishQRGlance()];
    }
}

function getApp() as swishQRApp {
    return Application.getApp() as swishQRApp;
}
