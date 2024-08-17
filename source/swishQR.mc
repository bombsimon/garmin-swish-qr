import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.WatchUi;

const BASE_URL = "https://swish-proxy-uybifb3biq-lz.a.run.app";
const APP_STORAGE_QR_CODE = "qrCode";
const APP_STORAGE_NUMBER = "Number";

class swishQR {
    var _isInitialStart as Boolean = true;
    var _image as WatchUi.BitmapResource? =
        Storage.getValue(APP_STORAGE_QR_CODE) as WatchUi.BitmapResource?;
    var _number as String? = Properties.getValue(APP_STORAGE_NUMBER) as String?;
    var _errorMessage as String?;

    function initialize() {
        if (isReady()) {
            if (validateNumber(_number as String)) {
                formatNumber();
            }
        }
    }

    private function isReady() as Boolean {
        return _image != null && _number != null;
    }

    function update(screenSize as Number) as Void {
        // Reset error message on all updates to clear state.
        _errorMessage = null;

        // We only try to fetch image if we have a valid number.
        _number = Properties.getValue(APP_STORAGE_NUMBER) as String?;
        if (_number == null || _number.equals("")) {
            return;
        }

        if (!validateNumber(_number as String)) {
            return;
        }

        fetchImage(screenSize, _number as String);
        formatNumber();
    }

    private function validateNumber(number as String) as Boolean {
        var numberAsString = _number as String;
        var numberAsNumber = numberAsString.toNumber();
        var numberLength =
            numberAsNumber == null
                ? 0
                : (numberAsNumber as Number).toString().length();

        if (
            numberAsString.length() != 10 ||
            numberAsNumber == null ||
            numberLength != 9
        ) {
            _errorMessage =
                "Number must be 10 digits, e.g. '0701234567'. Please update your settings in the Connect IQ app";

            WatchUi.requestUpdate();

            return false;
        }

        return true;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_errorMessage != null) {
            drawMessage(dc, _errorMessage as String);
            return;
        }

        if (!isReady()) {
            drawMessage(dc, "Setup in Connect IQ app");

            // If it's the first initial start and we're not ready, ensure we
            // check for settings and if the user configured the app non staretd
            // or in glance viwe, try to update the image.
            if (_isInitialStart) {
                _isInitialStart = false;
                update(dc.getWidth());
            }

            return;
        }

        _isInitialStart = false;

        var w = dc.getWidth();
        var h = dc.getHeight();

        var i = _image as WatchUi.BitmapResource;
        var imgW = i.getWidth();
        var imgH = i.getHeight();
        var x = w / 2 - imgW / 2;
        var y = h / 2 - imgH / 2;
        var f = Graphics.getFontHeight(Graphics.FONT_XTINY);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, w, h);

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

    private function drawMessage(dc as Graphics.Dc, message as String) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            w / 2,
            h / 2,
            Graphics.FONT_XTINY,
            Graphics.fitTextToArea(
                message,
                Graphics.FONT_XTINY,
                w - 20,
                h,
                true
            ),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
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

    private function fetchImage(
        screenSize as Number,
        number as String
    ) as Void {
        // System.println("Making request");

        // Compute how big of an image can fit a round screen.
        var size = (screenSize / Math.sqrt(2)).toNumber();

        var options = {
            :maxWidth => size,
            :maxHeight => size,
            :dithering => Communications.IMAGE_DITHERING_NONE,
        };

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
            Lang.format(BASE_URL + "/$1$", [number]),
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
            _image = data as WatchUi.BitmapResource;
            Storage.setValue(APP_STORAGE_QR_CODE, _image);

            WatchUi.requestUpdate();
        } else {
            System.println(
                Lang.format("Failed to fetch image: $1$ ($2$)", [
                    data,
                    responseCode,
                ])
            );
            _errorMessage =
                "Failed to generate QR code. Control your settings and try again.";
        }
    }
}
