import Toybox.WatchUi;
import Toybox.Lang;

class swishQRGlance extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function getLayout() as Void {
        setLayout([]);
    }

    function onSettingsChanged() as Void {}

    function onUpdate(dc) {
        GlanceView.onUpdate(dc);

        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;
        var text = "Swish QR";
        var textHeight = Graphics.getFontHeight(font);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            5,
            height / 2 - textHeight / 2,
            font,
            text,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }
}
