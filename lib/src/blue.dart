import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../bluetooth_print_plus.dart';

class BluetoothPrintPlus {
  BluetoothPrintPlus._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });
  }

  static final BluetoothPrintPlus _instance = BluetoothPrintPlus._();

  static BluetoothPrintPlus get instance => _instance;

  static const MethodChannel _channel =
      MethodChannel("bluetooth_print_plus/methods");
  static const EventChannel _stateChannel =
      EventChannel('bluetooth_print_plus/state');

  Stream<MethodCall> get _methodStream => _methodStreamController.stream;
  final StreamController<MethodCall> _methodStreamController =
      StreamController.broadcast();

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  Stream<bool> get isScanning => _isScanning.stream;

  final BehaviorSubject<List<BluetoothDevice>> _scanResults =
      BehaviorSubject.seeded([]);

  Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;

  final PublishSubject _stopScanPill = PublishSubject();

  /// Gets the current state of the Bluetooth module
  Stream<BPPState> get state async* {
    yield await _channel.invokeMethod('state').then((s) {
      if (s == 0) {
        return BPPState.blueOn;
      } else if (s == 1) {
        return BPPState.blueOff;
      } else if (s == 2) {
        return BPPState.deviceConnected;
      } else if (s == 3) {
        return BPPState.deviceDisconnected;
      }
      return BPPState.deviceDisconnected;
    });

    yield* _stateChannel.receiveBroadcastStream().map((s) {
      if (s == 0) {
        return BPPState.blueOn;
      } else if (s == 1) {
        return BPPState.blueOff;
      } else if (s == 2) {
        return BPPState.deviceConnected;
      } else if (s == 3) {
        return BPPState.deviceDisconnected;
      }
      return BPPState.deviceDisconnected;
    });
  }

  /// peripheral data feedback, receive and listen;
  Stream<Uint8List> get receivedData async* {
    yield* BluetoothPrintPlus.instance._methodStream
        .where((m) => m.method == "ReceivedData")
        .map((m) {
      return m.arguments;
    });
  }

  /// Starts a scan for Bluetooth Low Energy devices
  /// Timeout closes the stream after a specified [Duration]
  Stream<BluetoothDevice> scan({
    Duration? timeout,
  }) async* {
    // Emit to isScanning
    _isScanning.add(true);
    final killStreams = <Stream>[];
    killStreams.add(_stopScanPill);
    if (timeout != null) {
      killStreams.add(Rx.timer(null, timeout));
    }
    // Clear scan results list
    _scanResults.add(<BluetoothDevice>[]);

    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      print('Error starting scan.');
      _stopScanPill.add(null);
      _isScanning.add(false);
      throw e;
    }

    yield* BluetoothPrintPlus.instance._methodStream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
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

  Future startScan({
    Duration? timeout,
  }) async {
    await scan(timeout: timeout).drain();
    return _scanResults.value;
  }

  /// Stops a scan for Bluetooth Low Energy devices
  Future stopScan() async {
    await _channel.invokeMethod('stopScan');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  Future<dynamic> connect(BluetoothDevice device) =>
      _channel.invokeMethod('connect', device.toJson());

  Future<dynamic> disconnect() => _channel.invokeMethod('disconnect');

  Future<dynamic> write(Uint8List? data) async {
    await _channel.invokeMethod('write', {"data": data});
  }
}
