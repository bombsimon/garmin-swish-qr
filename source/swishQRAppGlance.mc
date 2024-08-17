import Toybox.WatchUi;
import Toybox.Lang;

(:glance)
class swishQRGlance extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function getLayout() as Void {
        setLayout([]);
    }

    function onSettingsChanged() as Void {}

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var font = Graphics.FONT_MEDIUM;
        var text = "Swish QR";
        var textHeight = Graphics.getFontHeight(font);

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(0, 0, width, height);

        // This isn't always in the middle, for some glance views there's extra
        // space under the actual area. However to make it consistent in code if
        // and when Garmin changes this let's just draw it in the middle.
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
