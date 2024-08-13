import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

class swishQRView extends WatchUi.View {
    var _image as WatchUi.BitmapResource?;
    var _number as String?;

    function initialize() {
        var number = Properties.getValue("Number") as String;
        var image = Storage.getValue("qrCode") as WatchUi.BitmapResource?;

        if (image != null && number != "") {
            System.println("Using cached image");
            updateQR(number, image);
        } else {
            System.println("Downloading image");
            fetchImage();
        }

        View.initialize();
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

            updateQR(_number as String, c);
        } else {
            System.println(responseCode);
        }
    }

    function updateQR(
        number as String,
        image as WatchUi.BitmapResource?
    ) as Void {
        var leading = number.substring(0, 3);
        var chunk1 = number.substring(3, 5);
        var chunk2 = number.substring(5, 7);
        var chunk3 = number.substring(7, null);

        _number = Lang.format("$1$-$2$ $3$ $4$", [
            leading,
            chunk1,
            chunk2,
            chunk3,
        ]);
        _image = image;

        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        _number = Properties.getValue("Number") as String;

        fetchImage();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
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

        if (_image != null && _number != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillRectangle(w / 2 - 130, h / 2 - 130, 260, 290);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawText(
                w / 2,
                h / 2 + 115,
                Graphics.FONT_XTINY,
                _number,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            var i = _image as WatchUi.BitmapResource;
            var imgW = i.getWidth();
            var imgH = i.getHeight();

            var x = w / 2 - imgW / 2;
            var y = h / 2 - imgH / 2;

            dc.drawBitmap(x, y, i);
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
