import 'dart:async';

import 'package:flutter/services.dart';

import '../bluetooth_print_plus.dart';

class BluetoothPrintPlus {
  BluetoothPrintPlus._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });
    _state.listen((event) {});
  }
  static final BluetoothPrintPlus _instance = BluetoothPrintPlus._();
  static BluetoothPrintPlus get instance => _instance;
  static const MethodChannel _channel =
      MethodChannel("bluetooth_print_plus/methods");
  static const EventChannel _stateChannel =
      EventChannel('bluetooth_print_plus/state');
  final StreamController<MethodCall> _methodStreamController =
      StreamController.broadcast();
  static final _scanResults =
      StreamControllerReEmit<List<BluetoothDevice>>(initialValue: []);
  static final _isScanning = StreamControllerReEmit<bool>(initialValue: false);
  static final _connectState = StreamControllerReEmit<ConnectState>(
      initialValue: ConnectState.disconnected);
  static final _blueState =
      StreamControllerReEmit<BlueState>(initialValue: BlueState.blueOn);
  static Timer? _scanTimeout;

  Stream<MethodCall> get _methodStream => _methodStreamController.stream;
  Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;
  Stream<bool> get isScanning => _isScanning.stream;
  Stream<ConnectState> get connectState => _connectState.stream;
  Stream<BlueState> get blueState => _blueState.stream;
  bool get isScanningNow => _isScanning.latestValue;
  bool get isConnected => _connectState.latestValue == ConnectState.connected;
  bool get isBlueOn => _blueState.latestValue == BlueState.blueOn;

  /// start scan for Bluetooth devices
  Future startScan({
    Duration? timeout,
  }) async {
    if (isScanningNow) {
      await stopScan();
    }
    await _scan(timeout: timeout).drain();
    return _scanResults.value;
  }

  /// stop scan for Bluetooth devices
  Future stopScan() async {
    if (isScanningNow) {
      await _channel.invokeMethod('stopScan');
      _isScanning.add(false);
      _scanTimeout?.cancel();
    } else {
      print("stopScan: already stopped");
    }
  }

  /// connect Bluetooth device
  Future<dynamic> connect(BluetoothDevice device) async {
    await _channel.invokeMethod('connect', device.toJson());
  }

  /// disconnect Bluetooth device
  Future<dynamic> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  /// write data to Bluetooth device
  Future<dynamic> write(Uint8List? data) async {
    await _channel.invokeMethod('write', {"data": data});
  }

  /// peripheral data feedback, receive and listen;
  Stream<Uint8List> get receivedData async* {
    yield* BluetoothPrintPlus.instance._methodStream
        .where((m) => m.method == "ReceivedData")
        .map((m) {
      return m.arguments;
    });
  }

  /// Gets the current state of the Bluetooth module
  Stream<int> get _state async* {
    yield await _channel.invokeMethod('state').then((s) {
      if (s <= 1) {
        if (s == 0) {
          _blueState.add(BlueState.blueOn);
        } else if (s == 1) {
          _blueState.add(BlueState.blueOff);
        }
      } else {
        if (s == 2) {
          _connectState.add(ConnectState.connected);
        } else if (s == 3) {
          _connectState.add(ConnectState.disconnected);
        }
      }
      return 1;
    });

    yield* _stateChannel.receiveBroadcastStream().map((s) {
      if (s <= 1) {
        if (s == 0) {
          _blueState.add(BlueState.blueOn);
        } else if (s == 1) {
          _blueState.add(BlueState.blueOff);
        }
      } else {
        if (s == 2) {
          _connectState.add(ConnectState.connected);
        } else if (s == 3) {
          _connectState.add(ConnectState.disconnected);
        }
      }
      return 1;
    });
  }

  /// Starts a scan for Bluetooth devices
  /// Timeout closes the stream after a specified [Duration]
  Stream<BluetoothDevice> _scan({Duration? timeout}) async* {
    // Emit to isScanning
    _isScanning.add(true);
    // Clear scan results list
    _scanResults.add(<BluetoothDevice>[]);
    // invoke startScan method
    await _channel
        .invokeMethod('startScan')
        .onError((error, stackTrace) => _isScanning.add(false));
    if (timeout != null) {
      _scanTimeout = Timer(timeout, stopScan);
    }

    yield* BluetoothPrintPlus.instance._methodStream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .map((map) {
      final device = BluetoothDevice.fromJson(Map<String, dynamic>.from(map));
      final List<BluetoothDevice> list = _scanResults.value;
      int newIndex = -1;
      list.asMap().forEach((index, e) {
        if (e.address == device.address) {
          newIndex = index;
        }
      });

      if (newIndex != -1) {
        list[newIndex] = device;
      } else {
        list.add(device);
      }
      _scanResults.add(list);
      return device;
    });
  }
}
