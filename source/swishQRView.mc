import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Application;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
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

class swishQRView extends WatchUi.View {
    // Screen size is used to calculate how big QR code we can show on the
    // screen. It's stored after loading the layout so we can update it without
    // having access to a draw context.
    var _screenSize as Number = 0;

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

    // Formatted number separates it just like Swish does when you generate a QR
    // code at https://www.swish.nu/marknadsmaterial. It's stored as a separate
    // variable so we can compare the settings hash.
    private var _formattedNumber as String = "";

    // If the `_errorMessage` is set, that text will be rendered instead of the
    // QR code. Used to render information about invalid settings or after a web
    // request failed.
    private var _errorMessage as String?;

    function initialize() {
        View.initialize();

        var settingsHash = Storage.getValue(APP_STORAGE_SETTINGS_HASH);
        if (settingsHash != null) {
            _settingsHash = settingsHash as Number;
        }

        // If the settings changed since last time we start (the current hash
        // doesn't match what's stored in our storage), set
        // `_shouldRequestUpdateOnStart` so we update the QR code first thing.
        var currentSettingsHash = allSettingsHash();
        if (_settingsHash != currentSettingsHash) {
            _shouldRequestUpdateOnStart = true;
            Storage.setValue(APP_STORAGE_SETTINGS_HASH, currentSettingsHash);
        }

        // If the QR code is read (we have an image and a number), format the
        // number so it gets stored in `_formattedNumber`.
        if (isReady() && validateNumber(_numberInSettings as String)) {
            formatNumber();
        }
    }

    // Store the screen size of the full screen when loading the layout.
    function onLayout(dc as Dc) as Void {
        _screenSize = dc.getWidth();
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {}

    // Update the view which only happens on demand for apps/widgets. It can
    // draw three different things:
    // 1. An error message if any is set
    // 2. Instructions on how to setup the app/QR code
    // 3. The actual QR code if valid and exist
    function onUpdate(dc as Dc) as Void {
        if (_errorMessage != null) {
            drawMessage(dc, _errorMessage as String);
            return;
        }

        if (_shouldRequestUpdateOnStart) {
            onSettingsChanged();
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

    // Draw an arbitrary message on the draw context. The text will be draw in
    // white on a black screen.
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
            // Requires API 3.1.0
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

    // Get a hash of all the available settings and their current value.
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

    // Compare the last settings the app saw with the current stored settings.
    // They could diff if the settings were changed when the app was closed.
    private function settingsChanged() as Boolean {
        return !_settingsHash.equals(allSettingsHash());
    }

    // Check if the app is ready by ensuring we have an image in our storage and
    // a number in our settings.
    private function isReady() as Boolean {
        return _image != null && _numberInSettings != null;
    }

    // Validate number by checking its length and that it only consists of
    // numbers. The number is stored as a string in the settings to allow for
    // the leading 0 which would otherwise be dropped but we still only want to
    // allow digits.
    // Currently this means that only mobile numbers that start with a 0 is
    // valid for this app.
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

            // Update the UI to display the error message we just set.
            WatchUi.requestUpdate();

            return false;
        }

        return true;
    }

    // Format the number to display under the QR code the same way Swish does
    // when you generate a QR code at https://www.swish.nu/marknadsmaterial.
    // E.g. 0701234567 => 070 123 45 67.
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

    // Called when settings are changed an the app is running, or if it was
    // requested upon startup. However we still do sanity check to see if they
    // actually changed by comparing the hashes, that way we don't download a
    // new image just because a user clicks "save" on the same settings.
    function onSettingsChanged() as Void {
        if (!settingsChanged()) {
            return;
        }

        // Reset error message on all updates to clear state.
        _errorMessage = null;

        // We only try to fetch image if we have a valid number.
        _numberInSettings = Properties.getValue(APP_SETTINGS_NUMBER) as String?;
        if (_numberInSettings == null) {
            return;
        }

        if (!validateNumber(_numberInSettings as String)) {
            return;
        }

        // Fetch an image and format the number to be displayed under the QR
        // code.
        fetchImage(_screenSize, _numberInSettings as String);
        formatNumber();

        // Update to our new settings.
        var newSettingsHash = allSettingsHash();
        _settingsHash = newSettingsHash;
        Storage.setValue(APP_STORAGE_SETTINGS_HASH, newSettingsHash);
    }

    // Fetch a Swish QR code with the current user settings.
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

    // Callback for async image request. If successful the image will be stored,
    // otherwise we display an error message. No matter the result we end by
    // requesting an update.
    function onRequestComplete(
        responseCode as Number,
        data as WatchUi.BitmapResource or Graphics.BitmapReference or Null
    ) as Void {
        if (responseCode == 200) {
            _image = data as WatchUi.BitmapResource;
            Storage.setValue(APP_STORAGE_QR_CODE, _image);
        } else {
            _errorMessage =
                "Failed to generate QR code. Control your settings and try again. Status " +
                responseCode;
        }

        WatchUi.requestUpdate();
    }
}
