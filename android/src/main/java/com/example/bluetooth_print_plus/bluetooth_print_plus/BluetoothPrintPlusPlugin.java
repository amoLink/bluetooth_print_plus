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
import android.util.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.gprinter.bean.PrinterDevices;
import com.gprinter.io.PortManager;
import com.gprinter.utils.Command;
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

import java.io.IOException;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * BluetoothPrintPlusPlugin
 * @author thon
 */
public class BluetoothPrintPlusPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, RequestPermissionsResultListener {
  private static final String TAG = "BluetoothPrintPlusPlugin";
  private Object initializationLock = new Object();
  private Context context;
  private ThreadPool threadPool;

  private MethodChannel channel;
  private MethodChannel tscChannel;
  private MethodChannel cpclChannel;
  private MethodChannel escChannel;
  private EventChannel stateChannel;
  private BluetoothManager mBluetoothManager;
  private BluetoothAdapter mBluetoothAdapter;

  private FlutterPluginBinding pluginBinding;
  private ActivityPluginBinding activityBinding;
  private Application application;
  private Activity activity;

  private Result pendingResult;
  private static final int REQUEST_FINE_LOCATION_PERMISSIONS = 1452;
  private static final int REQUEST_COARSE_LOCATION_PERMISSIONS = 1451;

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
            null,
            activityBinding);
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
    final PluginRegistry.Registrar registrar,
    final ActivityPluginBinding activityBinding
  ) {
    synchronized (initializationLock) {
      Log.i(TAG, "setup");
      this.activity = activity;
      this.application = application;
      this.context = application;
      channel = new MethodChannel(messenger,  "bluetooth_print_plus/methods");
      channel.setMethodCallHandler(this);

      tscChannel = new MethodChannel(messenger, "bluetooth_print_plus_tsc");
      tscCommandPlugin.setUpChannel(tscChannel);

      cpclChannel = new MethodChannel(messenger, "bluetooth_print_plus_cpcl");
      cpclCommandPlugin.setUpChannel(cpclChannel);

      escChannel = new MethodChannel(messenger, "bluetooth_print_plus_esc");
      escCommandPlugin.setUpChannel(escChannel);

      stateChannel = new EventChannel(messenger, "bluetooth_print_plus/state");
      stateChannel.setStreamHandler(stateHandler);
      mBluetoothManager = (BluetoothManager) application.getSystemService(Context.BLUETOOTH_SERVICE);
      mBluetoothAdapter = mBluetoothManager.getAdapter();
      if (registrar != null) {
        // V1 embedding setup for activity listeners.
        registrar.addRequestPermissionsResultListener(this);
      } else {
        // V2 embedding setup for activity listeners.
        activityBinding.addRequestPermissionsResultListener(this);
      }
    }
  }

  private void tearDown() {
    Log.i(TAG, "teardown");
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
    switch (call.method){
      case "state":
        state(result);
        break;
      case "isAvailable":
        result.success(mBluetoothAdapter != null);
        break;
      case "isOn":
        result.success(mBluetoothAdapter.isEnabled());
        break;
      case "isConnected":
        result.success(threadPool != null);
        break;
      case "startScan": {
        startScan(call, result);
        result.success(null);
      }
        break;
      case "stopScan":
        stopScan();
        result.success(null);
        break;
      case "connect":
        Map<String, Object> args = call.arguments();
        assert args != null;
        final String address = (String) args.get("address");
        connect(address);
        result.success(null);
        break;
      case "disconnect":
        Printer.close();
        result.success(null);
        break;
      case "destroy":
        result.success(destroy());
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

  private final BroadcastReceiver mFindBlueToothReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      // When discovery finds a device
      if (BluetoothDevice.ACTION_FOUND.equals(action)) {
        BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
        BluetoothParameter parameter = new BluetoothParameter();
        int rssi = intent.getExtras().getShort(BluetoothDevice.EXTRA_RSSI);//获取蓝牙信号强度
        if (device != null && device.getName() != null) {
          parameter.setBluetoothName(device.getName());
        } else {
          parameter.setBluetoothName("unKnow");
        }
        parameter.setBluetoothMac(device.getAddress());
        parameter.setBluetoothStrength(rssi+ "");
        if(device != null && device.getName() != null){
          Log.e(TAG,"\nBlueToothName:\t"+device.getName()+"\nMacAddress:\t"+device.getAddress()+"\nrssi:\t"+rssi);
          invokeMethodUIThread("ScanResult", device);
        }
      } else if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)){
        int bluetooth_state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                BluetoothAdapter.ERROR);
        if (bluetooth_state==BluetoothAdapter.STATE_OFF) {//关闭
//          finish();
        }
        if (bluetooth_state==BluetoothAdapter.STATE_ON) {//开启

        }
      }
    }
  };

  private void initBroadcast() {
    try {
      IntentFilter filter = new IntentFilter();
      filter.addAction(BluetoothDevice.ACTION_FOUND);
      filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
      // Register for broadcasts when discovery has finished
      filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);//蓝牙状态改变
      context.registerReceiver(mFindBlueToothReceiver, filter);
    } catch (Exception e){

    }
  }

  /**
   * 获取状态
   */
  private void state(Result result){
    try {
      switch(mBluetoothAdapter.getState()) {
        case BluetoothAdapter.STATE_OFF:
          result.success(BluetoothAdapter.STATE_OFF);
          break;
        case BluetoothAdapter.STATE_ON:
          result.success(BluetoothAdapter.STATE_ON);
          break;
        case BluetoothAdapter.STATE_TURNING_OFF:
          result.success(BluetoothAdapter.STATE_TURNING_OFF);
          break;
        case BluetoothAdapter.STATE_TURNING_ON:
          result.success(BluetoothAdapter.STATE_TURNING_ON);
          break;
        default:
          result.success(0);
          break;
      }
    } catch (SecurityException e) {
      result.error("invalid_argument", "argument 'address' not found", null);
    }
  }

  private void startScan(MethodCall call, Result result) {
    Log.d(TAG,"start scan ");
    try {
      int p1 = ContextCompat.checkSelfPermission(activity,Manifest.permission.ACCESS_COARSE_LOCATION);
      int p2 = ContextCompat.checkSelfPermission(activity,Manifest.permission.ACCESS_FINE_LOCATION);
      if (p1 != PackageManager.PERMISSION_GRANTED || p2 != PackageManager.PERMISSION_GRANTED) {
        ActivityCompat.requestPermissions(activity,
                new String[] {
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                }, REQUEST_FINE_LOCATION_PERMISSIONS);

        pendingResult = result;
      }
      startScan();
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
        Log.w(TAG,"invokeMethodUIThread: tried to call method on closed channel: " + name);
      }
    });
  }

  private ScanCallback mScanCallback = new ScanCallback() {
    @Override
    public void onScanResult(int callbackType, ScanResult result) {
      BluetoothDevice device = result.getDevice();
      if(device != null && device.getName() != null){
        invokeMethodUIThread("ScanResult", device);
      }
    }
  };

  private void startScan() throws IllegalStateException {
    initBroadcast();
    mBluetoothAdapter.startDiscovery();
  }

  private void stopScan() {
    BluetoothLeScanner scanner = mBluetoothAdapter.getBluetoothLeScanner();
    if(scanner != null) {
      scanner.stopScan(mScanCallback);
    }
  }

  public PortManager portManager=null;
  /**
   * 连接
   */
  public void connect(final String mac){
    ThreadPoolManager.getInstance().addTask(new Runnable() {
      @Override
      public void run() {
        if (portManager!=null) {//先close上次连接
          portManager.closePort();
          try {
            Thread.sleep(2000);
          } catch (InterruptedException e) {
          }
        }
        if (mac != null) {
          PrinterDevices blueTooth=new PrinterDevices.Build()
                  .setContext(context)
                  .setConnMethod(ConnMethod.BLUETOOTH)
                  .setMacAddress(mac)
                  .setCommand(Command.TSC)
                  .build();
          Printer.connect(blueTooth);
        }
      }
    });
  }

  private boolean destroy() {
//    DeviceConnFactoryManager.closeAllPort();
    if (threadPool != null) {
      threadPool.stopThreadPool();
    }
    return true;
  }

  @SuppressWarnings("unchecked")
  private boolean write(byte[] datas) throws IOException {
    boolean result =  Printer.getPortManager().writeDataImmediately(datas);
    if (result) {
      System.out.println("发送成功");
    }else {
      System.out.println("发送失败");
    }

    return result;
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    Log.d(TAG,"onRequestPermissionsResult ");
    for (int i = 0; i < permissions.length; i++) {
      Log.d(TAG, permissions[i]);
    }
    if (requestCode == REQUEST_FINE_LOCATION_PERMISSIONS || requestCode == REQUEST_COARSE_LOCATION_PERMISSIONS) {
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
        Log.d(TAG, "stateStreamHandler, current action: " + action);

        if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
          threadPool = null;
          sink.success(intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1));
        } else if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
          sink.success(1);
        } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
          threadPool = null;
          sink.success(0);
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

  static class Signal implements Comparator {
    public int compare(Object object1, Object object2) {// 实现接口中的方法
      BluetoothParameter p1 = (BluetoothParameter) object1; // 强制转换
      BluetoothParameter p2 = (BluetoothParameter) object2;
      return p1.getBluetoothStrength().compareTo(p2.getBluetoothStrength());
    }
  }

}
