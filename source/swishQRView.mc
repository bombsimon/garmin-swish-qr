import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

class swishQRView extends WatchUi.View {
    var _swishQR as swishQR;
    var _screenSize as Number = 0;

    function initialize(sq as swishQR) {
        _swishQR = sq;
        View.initialize();
    }

    function onSettingsChanged() as Void {
        _swishQR.update(_screenSize);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        _screenSize = dc.getWidth();
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        _swishQR.draw(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {}
}
