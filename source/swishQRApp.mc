import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

class swishQRApp extends Application.AppBase {
    var _sw as swishQRView = new swishQRView();
    var _image as WatchUi.BitmapResource or Graphics.BitmapReference or Null;
    var _number as String;

    function initialize() {
        _number = Properties.getValue("Number") as String;

        var image = Storage.getValue("qrCode") as WatchUi.BitmapResource?;

        if (image != null && _number != "") {
            System.println("Using cached image");
            _sw.updateQR(_number as String, image);
        } else {
            System.println("Downloading image");
            fetchImage();
        }

        AppBase.initialize();
    }

    function fetchImage() as Void {
        var options = {
            :maxWidth => 240,
            :maxHeight => 240,
            :dithering => Communications.IMAGE_DITHERING_NONE,
        };

        if (_number == "") {
            System.println("No settings, update to change");
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
        };

        Communications.makeImageRequest(
            Lang.format("https://swish-proxy-uybifb3biq-lz.a.run.app/$1$", [
                _number,
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

            _sw.updateQR(_number as String, c);
        } else {
            System.println(responseCode);
        }
    }

    function onSettingsChanged() {
        _number = Properties.getValue("Number") as String;
        fetchImage();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [_sw];
    }
}

function getApp() as swishQRApp {
    return Application.getApp() as swishQRApp;
}
