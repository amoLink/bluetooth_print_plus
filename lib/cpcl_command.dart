
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'enum.dart';

class CpclCommand extends PlatformInterface {
  final methodChannel = const MethodChannel('bluetooth_print_plus_cpcl');
  static final Object _token = Object();

  CpclCommand() : super(token: _token);

  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

  Future<void> size({
    required width,
    required height,
    int copies = 1
  }) async {
    Map<String, dynamic> params = {"width": width, "height": height, "copies": copies};
    await methodChannel.invokeMethod<void>('size', params);
  }

  Future<void> image({
    required Uint8List image,
    int x = 0,
    int y = 0,
  }) async {
    Map<String, dynamic> params = {
      "x": x,
      "y": y,
      "image": image
    };
    await methodChannel.invokeMethod<void>('image', params);
  }

  Future<void> print() async {
    await methodChannel.invokeMethod<void>('print');
  }



  // int _getRotation(Rotation rotation) {
  //   switch(rotation) {
  //     case Rotation.r_0:
  //       return 0;
  //     case Rotation.r_90:
  //       return 90;
  //     case Rotation.r_180:
  //       return 180;
  //     case Rotation.r_270:
  //       return 270;
  //   }
  // }
  //
  // String _getCodeType(BarCodeType codeType) {
  //   switch(codeType) {
  //     case BarCodeType.c_128:
  //       return "128";
  //     case BarCodeType.c_39:
  //       return "39";
  //     case BarCodeType.c_93:
  //       return "93";
  //     case BarCodeType.c_ITF:
  //       return "ITF";
  //     case BarCodeType.c_UPCA:
  //       return "UPCA";
  //     case BarCodeType.c_UPCE:
  //       return "UPCE";
  //     case BarCodeType.c_CODABAR:
  //       return "CODABAR";
  //     case BarCodeType.c_EAN8:
  //       return "EAN8";
  //     case BarCodeType.c_EAN13:
  //       return "EAN13";
  //   }
  // }
}