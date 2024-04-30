import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_print_plus_method_channel.dart';

abstract class BluetoothPrintPlusPlatform extends PlatformInterface {
  /// Constructs a BluetoothPrintPlusPlatform.
  BluetoothPrintPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothPrintPlusPlatform _instance = MethodChannelBluetoothPrintPlus();

  /// The default instance of [BluetoothPrintPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothPrintPlus].
  static BluetoothPrintPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothPrintPlusPlatform] when
  /// they register themselves.
  static set instance(BluetoothPrintPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> selfTest() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

}
