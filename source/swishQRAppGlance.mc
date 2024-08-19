import Toybox.WatchUi;
import Toybox.Lang;

(:glance)
class swishQRGlance extends WatchUi.GlanceView {
    private var _appName as String =
        WatchUi.loadResource(Rez.Strings.AppName) as String;

    function initialize() {
        GlanceView.initialize();
    }

    function getLayout() as Void {}

    function onUpdate(dc) {
        var height = dc.getHeight();

        var font = Graphics.FONT_MEDIUM;
        var textHeight = Graphics.getFontHeight(font);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            5,
            height / 2 - textHeight / 2,
            font,
            _appName,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }
}
