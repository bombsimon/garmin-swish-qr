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
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, w, h);

        if (_swishQR.isReady()) {
            _swishQR.draw(dc);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(
                w / 2,
                h / 2,
                Graphics.FONT_XTINY,
                "Setup in Connect IQ app",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {}
}
