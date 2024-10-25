package com.example.bluetooth_print_plus.bluetooth_print_plus;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;

import com.example.bluetooth_print_plus.bluetooth_print_plus.payload.BPPState;
import com.example.bluetooth_print_plus.bluetooth_print_plus.payload.BluetoothParameter;
import com.example.bluetooth_print_plus.bluetooth_print_plus.payload.Printer;
import com.example.bluetooth_print_plus.bluetooth_print_plus.payload.ThreadPool;
import com.example.bluetooth_print_plus.bluetooth_print_plus.payload.ThreadPoolManager;
import com.gprinter.bean.PrinterDevices;
import com.gprinter.io.PortManager;
import com.gprinter.utils.CallbackListener;
import com.gprinter.utils.Command;
import com.gprinter.utils.LogUtils;
import com.gprinter.utils.ConnMethod;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.*;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
import pub.devrel.easypermissions.EasyPermissions;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * BluetoothPrintPlusPlugin
 * 
 * @author amoLink
 */
public class BluetoothPrintPlusPlugin
    implements FlutterPlugin, ActivityAware, MethodCallHandler, RequestPermissionsResultListener {
  private static final String TAG = "BluetoothPrintPlusPlugin";
  private static final int REQUEST_LOCATION_PERMISSIONS = 1452;
  private final Object initializationLock = new Object();
  private Context context;
  private Application application;
  private Activity activity;
  private Result pendingResult;
  private ThreadPool threadPool;
  public PortManager portManager = null;
  private BluetoothManager mBluetoothManager;
  private BluetoothAdapter mBluetoothAdapter;

  private FlutterPluginBinding pluginBinding;
  private ActivityPluginBinding activityBinding;
  private MethodChannel channel;
  private MethodChannel tscChannel;
  private MethodChannel cpclChannel;
  private MethodChannel escChannel;
  private EventChannel stateChannel;
  private final TscCommandPlugin tscCommandPlugin = new TscCommandPlugin();
  private final CpclCommandPlugin cpclCommandPlugin = new CpclCommandPlugin();
  private final EscCommandPlugin escCommandPlugin = new EscCommandPlugin();

  public BluetoothPrintPlusPlugin() {}

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    pluginBinding = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    activityBinding = binding;
    setup(
        pluginBinding.getBinaryMessenger(),
        (Application) pluginBinding.getApplicationContext(),
        activityBinding.getActivity(),
        activityBinding
    );
  }

  @Override
  public void onDetachedFromActivity() {
    tearDown();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  private void setup(
      final BinaryMessenger messenger,
      final Application application,
      final Activity activity,
      final ActivityPluginBinding activityBinding
  ) {
    synchronized (initializationLock) {
      LogUtils.i(TAG, "setup");
      this.activity = activity;
      this.application = application;
      this.context = application;
      channel = new MethodChannel(messenger, "bluetooth_print_plus/methods");
      channel.setMethodCallHandler(this);
      // tsc Channel
      tscChannel = new MethodChannel(messenger, "bluetooth_print_plus_tsc");
      tscCommandPlugin.setUpChannel(tscChannel);
      // cpcl Channel
      cpclChannel = new MethodChannel(messenger, "bluetooth_print_plus_cpcl");
      cpclCommandPlugin.setUpChannel(cpclChannel);
      // esc Channel
      escChannel = new MethodChannel(messenger, "bluetooth_print_plus_esc");
      escCommandPlugin.setUpChannel(escChannel);
      // state Channel
      stateChannel = new EventChannel(messenger, "bluetooth_print_plus/state");
      stateChannel.setStreamHandler(stateHandler);
      mBluetoothManager = (BluetoothManager) application.getSystemService(Context.BLUETOOTH_SERVICE);
      mBluetoothAdapter = mBluetoothManager.getAdapter();

      activityBinding.addRequestPermissionsResultListener(this);
    }
  }

  private void tearDown() {
    LogUtils.i(TAG, "teardown");
    context = null;
    activityBinding.removeRequestPermissionsResultListener(this);
    activityBinding = null;
    channel.setMethodCallHandler(null);
    channel = null;
    stateChannel.setStreamHandler(null);
    stateChannel = null;
    mBluetoothAdapter = null;
    mBluetoothManager = null;
    application = null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (mBluetoothAdapter == null && !"isAvailable".equals(call.method)) {
      result.error("bluetooth_unavailable", "the device does not have bluetooth", null);
      return;
    }
    switch (call.method) {
      case "state":
        state(result);
        break;
      case "startScan":
        startScan(call, result);
        break;
      case "stopScan":
        stopScan();
        result.success(null);
        break;
      case "connect":
        Map<String, Object> args = call.arguments();
        assert args != null;
        final String address = (String) args.get("address");
        stopScan();
        connect(address);
        result.success(null);
        break;
      case "disconnect":
        Printer.close();
        result.success(null);
        break;
      case "write":
        byte[] bytes = call.argument("data");
        try {
          result.success(write(bytes));
        } catch (IOException e) {
          throw new RuntimeException(e);
        }
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void initBroadcast() {
    try {
      IntentFilter filter = new IntentFilter();
      filter.addAction(BluetoothDevice.ACTION_FOUND);
      filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
      // Register for broadcasts when discovery has finished
      filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);// 蓝牙状态改变
      // context.registerReceiver(mFindBlueToothReceiver, filter);
    } catch (Exception ignored) {

    }
  }

//  private final BroadcastReceiver mFindBlueToothReceiver = new BroadcastReceiver() {
//    @Override
//    public void onReceive(Context context, Intent intent) {
//      String action = intent.getAction();
//      if (BluetoothDevice.ACTION_FOUND.equals(action)) {
//        BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
//        if (device == null || device.getName() == null) return;
//        BluetoothParameter parameter = new BluetoothParameter();
//        int rssi = Objects.requireNonNull(intent.getExtras()).getShort(BluetoothDevice.EXTRA_RSSI);
//        parameter.setBluetoothName(device.getName());
//        parameter.setBluetoothMac(device.getAddress());
//        parameter.setBluetoothStrength(rssi + "");
//        LogUtils.i(TAG, "\nBlueToothName: " + device.getName() + "\nMacAddress: " + device.getAddress() + "\nrssi: " + rssi);
//        invokeMethodUIThread("ScanResult", device);
//      }
//    }
//  };

  private void state(Result result) {
    try {
      switch (mBluetoothAdapter.getState()) {
        case BluetoothAdapter.STATE_OFF:
          result.success(BPPState.BlueOff.getValue());
          break;
        case BluetoothAdapter.STATE_ON:
          result.success(BPPState.BlueOn.getValue());
          break;
        default:
          break;
      }
    } catch (SecurityException e) {
      result.error("invalid_argument", "argument 'address' not found", null);
    }
  }

  private void startScan(MethodCall call, Result result) {
    LogUtils.i(TAG, "start scan...");
    try {
      String[] perms = {
          Manifest.permission.BLUETOOTH,
          Manifest.permission.BLUETOOTH_ADMIN,
          Manifest.permission.BLUETOOTH_CONNECT,
          Manifest.permission.BLUETOOTH_SCAN,
          Manifest.permission.ACCESS_FINE_LOCATION,
      };
      if (EasyPermissions.hasPermissions(this.context, perms)) {
        // Already have permission, do the thing
        startScan();
      } else {
        // Do not have permissions, request them now
        EasyPermissions.requestPermissions(
            this.activity,
            "Bluetooth requires location permission!!!",
            REQUEST_LOCATION_PERMISSIONS,
            perms);
      }
      result.success(null);
    } catch (Exception e) {
      result.error("startScan", e.getMessage(), e);
    }
  }

  private void invokeMethodUIThread(final String name, final BluetoothDevice device) {
    final Map<String, Object> ret = new HashMap<>();
    ret.put("address", device.getAddress());
    ret.put("name", device.getName());
    ret.put("type", device.getType());
    new Handler(Looper.getMainLooper()).post(() -> {
      if (!ret.isEmpty()) {
        channel.invokeMethod(name, ret);
      } else {
        LogUtils.w(TAG, "invokeMethodUIThread: tried to call method on closed channel: " + name);
      }
    });
  }

  private final ScanCallback mScanCallback = new ScanCallback() {
    @Override
    public void onScanResult(int callbackType, ScanResult result) {
      BluetoothDevice device = result.getDevice();
      if (device != null && device.getName() != null) {
        LogUtils.i(TAG, "\nBlueToothName: " + device.getName() + "\nMacAddress: " + device.getAddress());
        invokeMethodUIThread("ScanResult", device);
      }
    }
  };

  private void startScan() throws IllegalStateException {
//    stopScan();
    initBroadcast();
//    mBluetoothAdapter.startDiscovery();
    BluetoothLeScanner scanner = mBluetoothAdapter.getBluetoothLeScanner();
    scanner.startScan(mScanCallback);
  }

  private void stopScan() {
    BluetoothLeScanner scanner = mBluetoothAdapter.getBluetoothLeScanner();
    if (scanner != null) {
      scanner.stopScan(mScanCallback);
    }
  }

  public void connect(final String mac) {
    ThreadPoolManager.getInstance().addTask(new Runnable() {
      @Override
      public void run() {
        if (portManager != null) {
          portManager.closePort();
          try {
              Thread.sleep(500);
          } catch (InterruptedException e) {
              throw new RuntimeException(e);
          }
        }
        if (mac != null) {
          PrinterDevices blueTooth = new PrinterDevices.Build()
              .setContext(context)
              .setConnMethod(ConnMethod.BLUETOOTH)
              .setMacAddress(mac)
              .setCommand(Command.CPCL)
              .setCallbackListener(new CallbackListener() {
                @Override
                public void onConnecting() {

                }

                @Override
                public void onCheckCommand() { }

                @Override
                public void onSuccess(PrinterDevices printerDevices) { }

                @Override
                public void onReceive(byte[] data) {
                  if (data == null) return;
                  // LogUtils.d(TAG, "Received Data: " + Arrays.toString(data));
                  new Handler(Looper.getMainLooper()).post(() -> {
                    channel.invokeMethod("ReceivedData", data);
                  });
                }

                @Override
                public void onFailure() { }

                @Override
                public void onDisconnect() { }
              })
              .build();
          Printer.connect(blueTooth);
        }
      }
    });
  }

  @SuppressWarnings("unchecked")
  private boolean write(byte[] data) throws IOException {
    boolean result = Printer.getPortManager().writeDataImmediately(data);
    LogUtils.d(TAG, result ? "发送成功": "发送失败");
    return result;
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    LogUtils.d(TAG, "onRequestPermissionsResult");
    if (requestCode == REQUEST_LOCATION_PERMISSIONS) {
      if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        startScan();
      } else {
        pendingResult.error("no_permissions", "this plugin requires location permissions for scanning", null);
        pendingResult = null;
      }
      return true;
    }
    return false;
  }

  private final StreamHandler stateHandler = new StreamHandler() {
    private EventSink sink;
    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
      @Override
      public void onReceive(Context context, Intent intent) {
        final String action = intent.getAction();
        LogUtils.d(TAG, "stateStreamHandler, current action: " + action);
        if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
          threadPool = null;
          // sink.success(intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1));
          int blueState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, 0);
          switch (blueState) {
            case BluetoothAdapter.STATE_ON:
              sink.success(BPPState.BlueOn.getValue());
              break;
            case BluetoothAdapter.STATE_OFF:
              sink.success(BPPState.BlueOff.getValue());
              break;
          }
        } else if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
          sink.success(BPPState.DeviceConnected.getValue());
        } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
          threadPool = null;
          sink.success(BPPState.DeviceDisconnected.getValue());
        }
      }
    };

    @Override
    public void onListen(Object o, EventSink eventSink) {
      sink = eventSink;
      IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
      filter.addAction(BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED);
      filter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
      filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
      context.registerReceiver(mReceiver, filter);
    }

    @Override
    public void onCancel(Object o) {
      sink = null;
      context.unregisterReceiver(mReceiver);
    }
  };
}
