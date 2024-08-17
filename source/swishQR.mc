import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.WatchUi;

const BASE_URL = "https://swish-proxy-uybifb3biq-lz.a.run.app";

// Keys for storage.
const APP_STORAGE_QR_CODE = "qrCode";
const APP_STORAGE_SETTINGS_HASH = "SettingsHash";

// Keys for settings.
const APP_SETTINGS_NUMBER = "Number";
const APP_SETTINGS_BORDER = "Border";
const APP_SETTINGS_COLOR = "Color";
const APP_SETTINGS_AMOUNT = "Amount";
const APP_SETTINGS_AMOUNT_E = "AmountEditable";
const APP_SETTINGS_MESSAGE = "Message";
const APP_SETTINGS_MESSAGE_E = "MessageEditable";

class swishQR {
    // To see if the user changed any settings while not running the app, we
    // store the hash of all settings. On startup we compare them and if they're
    // not the same we try to update the image.
    private var _settingsHash as Number = 0;
    private var _shouldRequestUpdateOnStart as Boolean = false;

    // We keep our image, our number from the settings and a formatted version
    // of the image at all times, only updating them when changes to settings
    // are detected.
    //
    // Storing images requires API version 3.0.0:
    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html#setValue-instance_function
    private var _image as WatchUi.BitmapResource? =
        Storage.getValue(APP_STORAGE_QR_CODE) as WatchUi.BitmapResource?;
    private var _numberInSettings as String? =
        Properties.getValue(APP_SETTINGS_NUMBER) as String?;
    private var _formattedNumber as String = "";

    // If the `_errorMessage` is set, that text will be rendered instead of the
    // QR code. Used to render information about invalid settings or after a web
    // request failed.
    private var _errorMessage as String?;

    function initialize() {
        var settingsHash = Storage.getValue(APP_STORAGE_SETTINGS_HASH);
        if (settingsHash != null) {
            _settingsHash = settingsHash as Number;
        }

        var currentSettingsHash = allSettingsHash();
        if (_settingsHash != currentSettingsHash) {
            _shouldRequestUpdateOnStart = true;
            Storage.setValue(APP_STORAGE_SETTINGS_HASH, currentSettingsHash);
        }

        if (isReady()) {
            if (validateNumber(_numberInSettings as String)) {
                formatNumber();
            }
        }
    }

    private function allSettingsHash() as Number {
        return Lang.format("$1$:$2$:$3$:$4$:$5$:$6$:$7$", [
            Properties.getValue(APP_SETTINGS_NUMBER) as String?,
            Properties.getValue(APP_SETTINGS_BORDER) as Number,
            Properties.getValue(APP_SETTINGS_COLOR) as Boolean,
            Properties.getValue(APP_SETTINGS_AMOUNT) as Number,
            Properties.getValue(APP_SETTINGS_AMOUNT_E) as Boolean,
            Properties.getValue(APP_SETTINGS_MESSAGE) as String,
            Properties.getValue(APP_SETTINGS_MESSAGE_E) as Boolean,
        ]).hashCode();
    }

    private function settingsChanged() as Boolean {
        return !_settingsHash.equals(allSettingsHash());
    }

    private function isReady() as Boolean {
        return _image != null && _numberInSettings != null;
    }

    private function validateNumber(number as String) as Boolean {
        var numberAsString = number as String;
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

    private function formatNumber() as Void {
        if (_numberInSettings == null) {
            return;
        }

        var number = _numberInSettings as String;
        var leading = number.substring(0, 3);
        var chunk1 = number.substring(3, 5);
        var chunk2 = number.substring(5, 7);
        var chunk3 = number.substring(7, 10);

        _formattedNumber = Lang.format("$1$-$2$ $3$ $4$", [
            leading,
            chunk1,
            chunk2,
            chunk3,
        ]);
    }

    function update(screenSize as Number) as Void {
        if (!settingsChanged()) {
            return;
        }

        // Reset error message on all updates to clear state.
        _errorMessage = null;

        // We only try to fetch image if we have a valid number.
        _numberInSettings = Properties.getValue(APP_SETTINGS_NUMBER) as String?;
        if (_numberInSettings == null || _numberInSettings.equals("")) {
            return;
        }

        if (!validateNumber(_numberInSettings as String)) {
            return;
        }

        fetchImage(screenSize, _numberInSettings as String);
        formatNumber();

        // Update to our new settings.
        var newSettingsHash = allSettingsHash();
        _settingsHash = newSettingsHash;
        Storage.setValue(APP_STORAGE_SETTINGS_HASH, newSettingsHash);
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_errorMessage != null) {
            drawMessage(dc, _errorMessage as String);
            return;
        }

        if (_shouldRequestUpdateOnStart) {
            update(dc.getWidth());
            _shouldRequestUpdateOnStart = false;
        }

        if (!isReady()) {
            drawMessage(dc, "Setup in Connect IQ app");
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

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, w, h);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillRectangle(x - 5, y - 5, imgW + 10, imgH + 10 + f);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(
            w / 2,
            h / 2 + imgH / 2,
            Graphics.FONT_XTINY,
            _formattedNumber,
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

    private function fetchImage(
        screenSize as Number,
        number as String
    ) as Void {
        System.println("Making request");

        // Compute how big of an image can fit a round screen.
        var size = (screenSize / Math.sqrt(2)).toNumber();

        var options = {
            :maxWidth => size,
            :maxHeight => size,
            :dithering => Communications.IMAGE_DITHERING_NONE,
        };

        var params = {
            "border" => Properties.getValue(APP_SETTINGS_BORDER) as Number,
            "color" => Properties.getValue(APP_SETTINGS_COLOR) as Boolean,
            "amount" => Properties.getValue(APP_SETTINGS_AMOUNT) as Number,
            "amount_editable" => Properties.getValue(APP_SETTINGS_AMOUNT_E) as
            Boolean,
            "message" => Properties.getValue(APP_SETTINGS_MESSAGE) as String,
            "message_editable" => Properties.getValue(APP_SETTINGS_MESSAGE_E) as
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
            _errorMessage =
                "Failed to generate QR code. Control your settings and try again. Status " +
                responseCode;
        }
    }
}
