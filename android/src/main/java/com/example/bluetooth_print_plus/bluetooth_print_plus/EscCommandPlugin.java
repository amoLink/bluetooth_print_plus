package com.example.bluetooth_print_plus.bluetooth_print_plus;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import androidx.annotation.NonNull;

import com.gprinter.command.EscCommand;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;


public class EscCommandPlugin implements FlutterPlugin, MethodCallHandler, RequestPermissionsResultListener {
    public MethodChannel channel;
    private static final String TAG = "BluetoothPrintPlusPlugin-ESC";

    private EscCommand escCommand;

    public EscCommand getEscCommand() {
        if (escCommand == null) {
            escCommand = new EscCommand();
            escCommand.addInitializePrinter();
        }
        return escCommand;
    }

    public void setUpChannel(MethodChannel channel) {
        this.channel = channel;
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "bluetooth_print_plus_esc");
        channel.setMethodCallHandler(this);
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Integer x = call.argument("x");
        Integer y = call.argument("y");
        String content = call.argument("content");
        Integer width = call.argument("width");
        Integer height = call.argument("height");
        Integer rotation = call.argument("rotation");
        Integer alignment = call.argument("alignment");
        String method = call.method;
        EscCommand.JUSTIFICATION align = EscCommand.JUSTIFICATION.LEFT;
        if (alignment != null) {
            switch (alignment) {
                case 1:
                    align = EscCommand.JUSTIFICATION.CENTER;
                    break;
                case 2:
                    align = EscCommand.JUSTIFICATION.RIGHT;
                    break;
            }
        }

        switch (method) {
            case "cleanCommand":
                this.escCommand = null;
                result.success(true);
                break;
            case "getCommand":
                Object[] elements = this.getEscCommand().getCommand().toArray();
                byte[] datas = new byte[elements.length];
                for (int i = 0; i < elements.length; i++) {
                    Byte item = (Byte) elements[i];
                    datas[i] = item;
                }
                result.success(datas);
                break;
            case "newline":
                this.getEscCommand().addPrintAndLineFeed();
                result.success(true);
                break;
            case "print":
                Integer feedLines = call.argument("feedLines");
                assert feedLines != null;
                this.getEscCommand().addPrintAndFeedLines((byte) feedLines.intValue());
                result.success(true);
                break;
            case "text":
                Integer printMode = call.argument("printMode");
                Integer size = call.argument("size");
                assert printMode != null;
                assert size != null;
                this.getEscCommand().addSelectJustification(align);
                this.getEscCommand().addSetCharcterSize(EscCommand.WIDTH_ZOOM.valueOf("MUL_" + (size + 1)), EscCommand.HEIGHT_ZOOM.valueOf("MUL_" + (size + 1)));
                switch (printMode) {
                    case 0x08:
                        this.getEscCommand().addSelectPrintModes(EscCommand.FONT.FONTA, EscCommand.ENABLE.ON, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF);
                        break;
                    case 0x80:
                        this.getEscCommand().addSelectPrintModes(EscCommand.FONT.FONTA, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.ON);
                        break;
                    case 0x88:
                        this.getEscCommand().addSelectPrintModes(EscCommand.FONT.FONTA, EscCommand.ENABLE.ON, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.ON);
                        break;
                    default:
                        break;
                }
                this.getEscCommand().addText(content);
                this.getEscCommand().addSetCharcterSize(EscCommand.WIDTH_ZOOM.MUL_1, EscCommand.HEIGHT_ZOOM.MUL_1);
                this.getEscCommand().addSelectPrintModes(EscCommand.FONT.FONTA, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF, EscCommand.ENABLE.OFF);
                result.success(true);
                break;
            case "code128":
                Integer hri = call.argument("hri");
                assert hri != null;
                assert width != null;
                assert height != null;
                assert alignment != null;
                this.getEscCommand().addSelectJustification(align);
                this.getEscCommand().addSelectJustification(align);
                this.getEscCommand().addSetBarcodeWidth(width.byteValue());
                this.getEscCommand().addSetBarcodeHeight(height.byteValue());
                EscCommand.HRI_POSITION position;
                switch (hri) {
                    case 1:
                        position = EscCommand.HRI_POSITION.ABOVE;
                        break;
                    case 2:
                        position = EscCommand.HRI_POSITION.BELOW;
                        break;
                    case 3:
                        position = EscCommand.HRI_POSITION.ABOVE_AND_BELOW;
                        break;
                    default:
                        position  = EscCommand.HRI_POSITION.NO_PRINT;
                        break;
                }
                this.getEscCommand().addSelectPrintingPositionForHRICharacters(position);
                result.success(true);
                break;
            case "qrCode":
                Integer sizee = call.argument("size");
                assert sizee != null;
                assert content != null;
                this.getEscCommand().addSelectJustification(align);
                this.getEscCommand().addSelectErrorCorrectionLevelForQRCode((byte) 0x31);
                this.getEscCommand().addSelectSizeOfModuleForQRCode((byte)sizee.intValue());
                this.getEscCommand().addStoreQRCodeData(content);
                result.success(true);
                break;
            case "image":
                byte[] bytes = call.argument("image");
                assert bytes != null;
                this.getEscCommand().addSelectJustification(align);
                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                this.getEscCommand().addOriginRastBitImage(bitmap, bitmap.getWidth(), 1);
                result.success(true);
                break;
            case "cutPaper":
                this.getEscCommand().addCutPaper();
                result.success(true);
                break;
            case "sound":
                Integer number = call.argument("number");
                Integer time = call.argument("time");
                assert number != null;
                assert time != null;
                this.getEscCommand().addSound((byte) number.intValue(), (byte) time.intValue());
                result.success(true);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        return false;
    }
}
