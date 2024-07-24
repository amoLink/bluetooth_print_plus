package com.example.bluetooth_print_plus.bluetooth_print_plus;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import androidx.annotation.NonNull;

import com.gprinter.command.LabelCommand;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;


public class TscCommandPlugin implements FlutterPlugin, MethodCallHandler, RequestPermissionsResultListener {
    public MethodChannel channel;
    private static final String TAG = "BluetoothPrintPlusPlugin-TSC";

    private final LabelCommand tscCommand = new LabelCommand();


    public void setUpChannel(MethodChannel channel) {
        this.channel = channel;
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "bluetooth_print_plus_tsc");
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
            case "selfTest":
                this.tscCommand.addSelfTest();
                result.success(true);
                break;
            case "cleanCommand":
                this.tscCommand.clrCommand();
                result.success(true);
                break;
            case "getCommand":
                Object[] elements = this.tscCommand.getCommand().toArray();
                byte[] datas = new byte[elements.length];
                for (int i = 0; i < elements.length; i++) {
                    Byte item = (Byte) elements[i];
                    datas[i] = item;
                }
                result.success(datas);
                break;
            case "print":
                Integer copies = call.argument("copies");
                assert copies != null;
                this.tscCommand.addPrint(1, copies);
                result.success(true);
                break;
            case "gap":
                Integer gap = call.argument("gap");
                assert gap != null;
                this.tscCommand.addGap(gap);
                result.success(true);
                break;
            case "speed":
                Integer speed = call.argument("speed");
                assert speed != null;
                this.tscCommand.addSpeed(LabelCommand.SPEED.valueOf("SPEED" + speed));
                result.success(true);
                break;
            case "density":
                Integer density = call.argument("density");
                assert density != null;
                this.tscCommand.addDensity(LabelCommand.DENSITY.valueOf("DNESITY" + density));
                result.success(true);
                break;
            case "cls":
                this.tscCommand.addCls();
                result.success(true);
                break;
            case "size":
                assert width != null;
                assert height != null;
                this.tscCommand.addSize(width, height);
                result.success(true);
                break;
            case "text":
                Integer xMulti = call.argument("xMulti");
                Integer yMulti = call.argument("yMulti");
                assert x != null;
                assert y != null;
                this.tscCommand.addText(
                        x, y,
                        LabelCommand.FONTTYPE.SIMPLIFIED_24_CHINESE,
                        LabelCommand.ROTATION.valueOf("ROTATION_" + rotation),
                        LabelCommand.FONTMUL.valueOf( "MUL_" + xMulti), LabelCommand.FONTMUL.valueOf("MUL_" + yMulti), content
                );
                result.success(true);
                break;
            case "image":
                byte[] bytes = call.argument("image");
                assert bytes != null;
                assert x != null;
                assert y != null;
                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                this.tscCommand.addBitmap(x, y, LabelCommand.BITMAP_MODE.OVERWRITE, bitmap.getWidth(), bitmap);
                result.success(true);
                break;
            case "barCode":
                String codeType = call.argument("codeType");
                Boolean readable = call.argument("readable");
                Integer narrow = call.argument("narrow");
                Integer wide = call.argument("wide");
                assert x != null;
                assert y != null;
                assert height != null;
                assert narrow != null;
                assert wide != null;
                this.tscCommand.add1DBarcode(
                    x, y,
                    getCodeType(codeType),
                    height,
                    Boolean.TRUE.equals(readable) ? LabelCommand.READABEL.EANBEL : LabelCommand.READABEL.DISABLE,
                    LabelCommand.ROTATION.valueOf("ROTATION_" + rotation),
                    narrow, wide, content
                );
                result.success(true);
                break;
            case "qrCode":
                Integer cellWidth = call.argument("cellWidth");
                assert x != null;
                assert y != null;
                assert cellWidth != null;
                this.tscCommand.addQRCode(
                    x, y,
                    LabelCommand.EEC.LEVEL_M,
                    cellWidth,
                    LabelCommand.ROTATION.valueOf("ROTATION_" + rotation),
                    content
                );
                result.success(true);
                break;
            case "bar":
                assert x != null;
                assert y != null;
                assert width != null;
                assert height != null;
                this.tscCommand.addBar(x, y, width, height);
                result.success(true);
                break;
            case "box":
                Integer endX = call.argument("endX");
                Integer endY = call.argument("endY");
                Integer linThickness = call.argument("linThickness");
                assert x != null;
                assert y != null;
                assert endX != null;
                assert endY != null;
                assert linThickness != null;
                this.tscCommand.addBox(
                    x, y,
                    endX, endY,
                    linThickness
                );
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

    public LabelCommand.BARCODETYPE getCodeType(String codeType) {
        switch (codeType) {
            case "39":
                return LabelCommand.BARCODETYPE.CODE39;
            case "93":
                return LabelCommand.BARCODETYPE.CODE93;
            case "ITF":
                return LabelCommand.BARCODETYPE.ITF14;
            case "UPCA":
                return LabelCommand.BARCODETYPE.UPCA;
            case "UPCE":
                return LabelCommand.BARCODETYPE.UPCE;
            case "CODABAR":
                return LabelCommand.BARCODETYPE.CODABAR;
            case "EAN8":
                return LabelCommand.BARCODETYPE.EAN8;
            case "EAN13":
                return LabelCommand.BARCODETYPE.EAN13;
            default:
                return LabelCommand.BARCODETYPE.CODE128;
        }
    }
}
