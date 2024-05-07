
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class EscCommand extends PlatformInterface {
  final methodChannel = const MethodChannel('bluetooth_print_plus_esc');
  static final Object _token = Object();

  EscCommand() : super(token: _token);

  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

  Future<void> image({
    required Uint8List image,
  }) async {
    Map<String, dynamic> params = {
      "image": image
    };
    await methodChannel.invokeMethod<void>('image', params);
  }

  Future<void> print({int feedLines = 4}) async {
    await methodChannel.invokeMethod<void>('print', {"feedLines": feedLines});
  }

}