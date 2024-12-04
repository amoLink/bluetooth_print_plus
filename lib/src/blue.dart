import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../bluetooth_print_plus.dart';

class BluetoothPrintPlus {
  static bool _initialized = false;
  static Future<dynamic> _initFlutterBluePlus() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    // set platform method handler
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      _methodStream.add(call);
    });
    _state.listen((event) {});
  }

  /// native platform methods channel
  static final MethodChannel _methodChannel =
      const MethodChannel("bluetooth_print_plus/methods");

  /// native platform events channel
  static final EventChannel _stateChannel =
      const EventChannel('bluetooth_print_plus/state');
  static final StreamController<MethodCall> _methodStream =
      StreamController.broadcast();

  /// stream used for the scanResults public api
  static final _scanResults =
      StreamControllerReEmit<List<BluetoothDevice>>(initialValue: []);

  /// stream used for the isScanning public api
  static final _isScanning = StreamControllerReEmit<bool>(initialValue: false);

  /// stream used for the isConnected public api
  static final _connectState = StreamControllerReEmit<ConnectState>(
      initialValue: ConnectState.disconnected);

  /// stream used for the isBlueOn public api
  static final _blueState =
      StreamControllerReEmit<BlueState>(initialValue: BlueState.blueOn);

  static PublishSubject _stopScanPill = new PublishSubject();

  /// a stream of scan results
  /// - if you re-listen to the stream it re-emits the previous results
  /// - the list contains all the results since the scan started
  /// - the returned stream is never closed.
  static Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;

  /// returns whether we are scanning as a stream
  static Stream<bool> get isScanning => _isScanning.stream;

  /// returns connect state as a stream
  static Stream<ConnectState> get connectState => _connectState.stream;

  /// returns blue state as a stream
  static Stream<BlueState> get blueState => _blueState.stream;

  /// are we scanning right now?
  static bool get isScanningNow => _isScanning.latestValue;

  /// blue device is connected now?
  static bool get isConnected =>
      _connectState.latestValue == ConnectState.connected;

  /// blue is on now?
  static bool get isBlueOn => _blueState.latestValue == BlueState.blueOn;

  /// the last known state
  static int? _stateNow;

  /// Start a scan for Bluetooth devices.
  ///
  /// [timeout] calls stopScan after a specified duration, Defaults to 15 seconds.
  ///
  /// If a scan is already in progress, it is stopped first.
  ///
  /// The scan results are emitted on the `scanResults` stream.
  ///
  /// The `timeout` parameter stops the scan after the specified duration.
  ///
  /// Returns the list of scanned devices.
  static Future startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _initFlutterBluePlus();
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
  static Future stopScan() async {
    if (isScanningNow) {
      _isScanning.add(false);
      _stopScanPill.add(null);
      await _methodChannel.invokeMethod('stopScan');
    } else {
      print("stopScan: already stopped");
    }
  }

  /// Connect to a Bluetooth device.
  ///
  /// [device] The device must have been previously discovered in a scan.
  ///
  /// The `connectState` stream is emitted with `connecting` while the
  /// connection is in progress, and `connected` if the connection is
  /// successful, or `disconnected` if the connection fails.
  ///
  /// The `connect` method returns immediately, and the connection status
  /// is reported on the `connectState` stream.
  static Future<dynamic> connect(BluetoothDevice device) async {
    await _methodChannel.invokeMethod('connect', device.toJson());
  }

  /// Disconnects from the currently connected Bluetooth device.
  ///
  /// If no device is connected, the method does nothing.
  ///
  /// The `connectState` stream is emitted with `disconnected` after a successful disconnection.
  ///
  /// Returns a `Future` that completes when the disconnection process is finished.
  static Future<dynamic> disconnect() async {
    await _methodChannel.invokeMethod('disconnect');
  }

  /// Sends data to the connected Bluetooth device.
  ///
  /// [data] The data to be sent should be provided as a `Uint8List`.
  ///
  /// This method uses a method channel to invoke the native 'write' method,
  /// passing the data as an argument.
  ///
  /// Returns a `Future` that completes when the write operation is finished.
  static Future<dynamic> write(Uint8List? data) async {
    await _methodChannel.invokeMethod('write', {"data": data});
  }

  /// peripheral data feedback, receive and listen;
  static Stream<Uint8List> get receivedData async* {
    yield* BluetoothPrintPlus._methodStream.stream
        .where((m) => m.method == "ReceivedData")
        .map((m) {
      return m.arguments;
    });
  }

  /// Gets the current state of the Bluetooth module
  static Stream<int> get _state async* {
    if (_stateNow == null) {
      var result = await _methodChannel.invokeMethod('state');
      // update _adapterStateNow if it is still null after the await
      if (_stateNow == null) {
        _stateNow = result;
      }
    }

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
  static Stream<BluetoothDevice> _scan({required Duration timeout}) async* {
    // Emit to isScanning
    _isScanning.add(true);
    // Clear scan results list
    _scanResults.add(<BluetoothDevice>[]);
    // invoke startScan method
    await _methodChannel.invokeMethod('startScan').onError((error, stackTrace) {
      _stopScanPill.add(null);
      _isScanning.add(false);
    });
    final killStreams = <Stream>[]..add(_stopScanPill);
    killStreams.add(Rx.timer(null, timeout));
    yield* BluetoothPrintPlus._methodStream.stream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
        .map((map) {
      final device = BluetoothDevice.fromJson(Map<String, dynamic>.from(map));
      final scanResults = _scanResults.value;
      int index = scanResults
          .indexWhere((element) => element.address == device.address);
      index == -1 ? scanResults.add(device) : scanResults[index] = device;
      _scanResults.add(scanResults);
      return device;
    });
  }
}
