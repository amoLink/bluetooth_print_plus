package com.example.bluetooth_print_plus.bluetooth_print_plus;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import androidx.annotation.NonNull;

import com.gprinter.command.CpclCommand;
import com.gprinter.command.LabelCommand;

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
