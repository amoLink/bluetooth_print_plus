package com.example.bluetooth_print_plus.bluetooth_print_plus;

import static com.gprinter.command.CpclCommand.COMMAND.BARCODE;
import static com.gprinter.command.CpclCommand.COMMAND.VBARCODE;
import static com.gprinter.command.CpclCommand.TEXT_FONT.FONT_3;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import androidx.annotation.NonNull;

import com.gprinter.command.CpclCommand;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;


public class CpclCommandPlugin implements FlutterPlugin, MethodCallHandler, RequestPermissionsResultListener {
    public MethodChannel channel;
    private static final String TAG = "BluetoothPrintPlusPlugin-TSC";

    private final CpclCommand cpclCommand = new CpclCommand();


    public void setUpChannel(MethodChannel channel) {
        this.channel = channel;
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "bluetooth_print_plus_cpcl");
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
        String method = call.method;

        switch (method) {
            case "cleanCommand":
                this.cpclCommand.clrCommand();
                result.success(true);
                break;
            case "getCommand":
                Object[] elements = this.cpclCommand.getCommand().toArray();
                byte[] datas = new byte[elements.length];
                for (int i = 0; i < elements.length; i++) {
                    Byte item = (Byte) elements[i];
                    datas[i] = item;
                }
                result.success(datas);
                break;
            case "print":
                this.cpclCommand.addPrint();
                result.success(true);
                break;
            case "form":
                this.cpclCommand.addForm();
                result.success(true);
                break;
            case "size":
                Integer copies = call.argument("copies");
                assert width != null;
                assert height != null;
                assert copies != null;
                this.cpclCommand.addInitializePrinter(height, copies);
                this.cpclCommand.addPagewidth(width);
                result.success(true);
                break;
            case "image":
                byte[] bytes = call.argument("image");
                assert bytes != null;
                assert x != null;
                assert y != null;
                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                this.cpclCommand.addCGraphics(x, y, bitmap.getWidth(), bitmap);
                result.success(true);
                break;
            case "text":
                Integer xMulti = call.argument("xMulti");
                Integer yMulti = call.argument("yMulti");
                Integer size = call.argument("size");
                Boolean bold = call.argument("bold");
                assert x != null;
                assert y != null;
                assert xMulti != null;
                assert yMulti != null;
                assert size != null;
                assert bold != null;
                if (bold) {
                    this.cpclCommand.addSETBOLD(1);
                }
                this.cpclCommand.addSetmag(xMulti, yMulti);
                this.cpclCommand.addText(FONT_3, size, x, y, content);
                if (bold) {
                    this.cpclCommand.addSETBOLD(0);
                }
                result.success(true);
                break;
            case "qrCode":
                assert x != null;
                assert y != null;
                assert width != null;
                this.cpclCommand.addBQrcode(x, y, 2, width, content);
                result.success(true);
                break;
            case "barCode":
                String codeType = call.argument("codeType");
                Boolean vertical = call.argument("vertical");
                assert vertical != null;
                assert height != null;
                assert width != null;
                assert x != null;
                assert y != null;
                assert codeType != null;
                CpclCommand.COMMAND command = vertical ? VBARCODE : BARCODE;
                CpclCommand.CPCLBARCODETYPE barcodeType;
                switch (codeType) {
                    case "UPCA":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.UPCA;
                        break;
                    case "UPCE":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.UPCE;
                        break;
                    case "EAN13":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.EAN_13;
                        break;
                    case "EAN8":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.EAN_8;
                        break;
                    case "39":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.CODE39;
                        break;
                    case "93":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.CODE93;
                        break;
                    case "CODABAR":
                        barcodeType = CpclCommand.CPCLBARCODETYPE.CODABAR;
                        break;
                    default:
                        barcodeType = CpclCommand.CPCLBARCODETYPE.CODE128;
                        break;
                }
                this.cpclCommand.addBarcode(command, barcodeType, width, CpclCommand.BARCODERATIO.Point2, height, x, y, content);
                result.success(true);
                break;
            case "line":
                Integer endX = call.argument("endX");
                Integer endY = call.argument("endY");
                assert x != null;
                assert y != null;
                assert endX != null;
                assert endY != null;
                assert width != null;
                this.cpclCommand.addLine(x, y, endX, endY, width);
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
