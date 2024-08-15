import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.WatchUi;

class swishQR {
    var _image as WatchUi.BitmapResource? =
        Storage.getValue("qrCode") as WatchUi.BitmapResource?;
    var _number as String? = Properties.getValue("Number") as String?;

    function initialize() {
        if (isReady()) {
            formatNumber();
            System.println("Using cached image");
        }
    }

    function isReady() as Boolean {
        return _image != null && _number != null;
    }

    function update(screenSize as Number) as Void {
        _number = Properties.getValue("Number") as String?;
        if (_number == null || _number == "") {
            return;
        }

        fetchImage(screenSize);
        formatNumber();
    }

    function draw(dc as Graphics.Dc) as Void {
        if (!isReady()) {
            return;
        }

        var w = dc.getWidth();
        var h = dc.getHeight();

        var i = _image as WatchUi.BitmapResource;
        var imgW = i.getWidth();
        var imgH = i.getHeight();
        var x = w / 2 - imgW / 2;
        var y = h / 2 - imgH / 2;
        var f = Graphics.getFontHeight(Graphics.FONT_XTINY);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillRectangle(x - 5, y - 5, imgW + 10, imgH + 10 + f);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(
            w / 2,
            h / 2 + imgH / 2,
            Graphics.FONT_XTINY,
            _number,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawBitmap(x, y, i);
    }

    private function formatNumber() as Void {
        if (_number == null) {
            return;
        }

        var number = _number as String;
        var leading = number.substring(0, 3);
        var chunk1 = number.substring(3, 5);
        var chunk2 = number.substring(5, 7);
        var chunk3 = number.substring(7, 10);

        _number = Lang.format("$1$-$2$ $3$ $4$", [
            leading,
            chunk1,
            chunk2,
            chunk3,
        ]);
    }

    private function fetchImage(screenSize as Number) as Void {
        // Compute how big of an image can fit a round screen.
        var size = (screenSize / Math.sqrt(2)).toNumber();

        var options = {
            :maxWidth => size,
            :maxHeight => size,
            :dithering => Communications.IMAGE_DITHERING_NONE,
        };

        var number = Properties.getValue("Number") as String?;
        if (number == null || number == "") {
            return;
        }

        var params = {
            "border" => Properties.getValue("Border") as Number,
            "color" => Properties.getValue("Color") as Boolean,
            "amount" => Properties.getValue("Amount") as Number,
            "amount_editable" => Properties.getValue("AmountEditable") as
            Boolean,
            "message" => Properties.getValue("Message") as String,
            "message_editable" => Properties.getValue("MessageEditable") as
            Boolean,
            "size" => size,
        };

        Communications.makeImageRequest(
            Lang.format("https://swish-proxy-uybifb3biq-lz.a.run.app/$1$", [
                number,
            ]),
            params,
            options,
            method(:onRequestComplete)
        );
    }

    function onRequestComplete(
        responseCode as Number,
        data as WatchUi.BitmapResource or Graphics.BitmapReference or Null
    ) as Void {
        if (responseCode == 200) {
            // Cast form reference to resource so we can persist it.
            var c = data as WatchUi.BitmapResource;
            Storage.setValue("qrCode", c);

            _image = c;

            WatchUi.requestUpdate();
        } else {
            System.println(
                Lang.format("Failed to fetch image: $1$ ($2$)", [
                    data,
                    responseCode,
                ])
            );
        }
    }
}
