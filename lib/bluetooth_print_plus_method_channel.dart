import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_print_plus_platform_interface.dart';

/// An implementation of [BluetoothPrintPlusPlatform] that uses method channels.
class MethodChannelBluetoothPrintPlus extends BluetoothPrintPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_print_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }


}
