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

  /// Start a scan for Bluetooth devices.
  ///
  /// If a scan is already in progress, it is stopped first.
  ///
  /// The scan results are emitted on the `scanResults` stream.
  ///
  /// The `timeout` parameter stops the scan after the specified duration.
  ///
  /// Returns the list of scanned devices.
  Future startScan({
    Duration? timeout,
  }) async {
    if (isScanningNow) {
      await stopScan();
    }
    await _scan(timeout: timeout).drain();
    return _scanResults.value;
  }

  /// Stop a scan for Bluetooth devices.
  ///
  /// If no scan is in progress, nothing happens.
  ///
  /// The `isScanning` stream is emitted with `false` when the scan is stopped.
  Future stopScan() async {
    if (isScanningNow) {
      await _channel.invokeMethod('stopScan');
      _isScanning.add(false);
      _scanTimeout?.cancel();
    } else {
      print("stopScan: already stopped");
    }
  }

  /// Connect to a Bluetooth device.
  ///
  /// The device must have been previously discovered in a scan.
  ///
  /// The `connectState` stream is emitted with `connecting` while the
  /// connection is in progress, and `connected` if the connection is
  /// successful, or `disconnected` if the connection fails.
  ///
  /// The `connect` method returns immediately, and the connection status
  /// is reported on the `connectState` stream.
  Future<dynamic> connect(BluetoothDevice device) async {
    await _channel.invokeMethod('connect', device.toJson());
  }

  /// Disconnects from the currently connected Bluetooth device.
  ///
  /// If no device is connected, the method does nothing.
  ///
  /// The `connectState` stream is emitted with `disconnected` after a successful disconnection.
  ///
  /// Returns a `Future` that completes when the disconnection process is finished.
  Future<dynamic> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  /// Sends data to the connected Bluetooth device.
  ///
  /// The data to be sent should be provided as a `Uint8List`.
  ///
  /// This method uses a method channel to invoke the native 'write' method,
  /// passing the data as an argument.
  ///
  /// Returns a `Future` that completes when the write operation is finished.
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

  /// Scans for nearby Bluetooth devices and emits them as a stream.
  ///
  /// If a `timeout` is provided, the scan will automatically stop after that
  /// duration. Otherwise, the scan will run indefinitely until `stopScan` is
  /// called.
  ///
  /// The stream will emit each discovered device as a [BluetoothDevice] object.
  /// The stream will also emit a list of all discovered devices via the
  /// `scanResults` stream.
  ///
  /// Note that the scan results are not guaranteed to be in any particular order.
  ///
  /// If the scan fails (for example, if the device does not have Bluetooth
  /// capabilities), the stream will emit an error and then close.
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
