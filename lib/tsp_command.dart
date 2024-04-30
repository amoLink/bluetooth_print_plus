

import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'enum.dart';

class TscCommand extends PlatformInterface {
  final methodChannel = const MethodChannel('bluetooth_print_plus_tsc');
  static final Object _token = Object();

  TscCommand() : super(token: _token);

  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  Future<void> selfTest() async {
    await methodChannel.invokeMethod<void>('selfTest');
  }

  Future<void> cls() async {
    await methodChannel.invokeMethod<void>('cls');
  }

  Future<void> gap(int gap) async {
    await methodChannel.invokeMethod<void>('gap');
  }

  /// speed : 2 ~ 12
  Future<void> speed(int speed) async {
    Map<String, dynamic> params = {"speed": speed};
    await methodChannel.invokeMethod<void>('speed', params);
  }

  /// density : 0 ~ 15
  Future<void> density(int density) async {
    Map<String, dynamic> params = {"density": density};
    await methodChannel.invokeMethod<void>('density', params);
  }

  Future<void> size({
    int width = 0,
    int height = 0
  }) async {
    Map<String, dynamic> params = {"width": width, "height": height};
    await methodChannel.invokeMethod<void>('size', params);
  }

  Future<void> text({
    required String content,
    int x = 0,
    int y = 0,
    int xMulti = 1,
    int yMulti = 1,
    Rotation rotation = Rotation.r_0,
  }) async {
    int rota = _getRotation(rotation);
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "xMulti": xMulti,
      "yMulti": yMulti,
      "rotation": rota
    };
    await methodChannel.invokeMethod<void>('text', params);
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

  Future<void> qrCode({
    required String content,
    int x = 0,
    int y = 0,
    int cellWidth = 6,
    Rotation rotation = Rotation.r_0,
  }) async {
    int rota = _getRotation(rotation);
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "cellWidth": cellWidth,
      "rotation": rota
    };
    await methodChannel.invokeMethod<void>('qrCode', params);
  }

  Future<void> barCode({
    required String content,
    int x = 0,
    int y = 0,
    BarCodeType codeType = BarCodeType.c_128,
    Rotation rotation = Rotation.r_0,
    int height = 100,
    bool readable = true,
    int narrow = 2,
    int wide = 4
  }) async {
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "codeType": _getCodeType(codeType),
      "rotation": _getRotation(rotation),
      "height": height,
      "readable": readable,
      "narrow": narrow,
      "wide": wide,
    };
    await methodChannel.invokeMethod<void>('barCode', params);
  }

  Future<void> bar({
    required int x,
    required int y,
    required int width,
    int height = 2,
  }) async {
    Map<String, dynamic> params = {
      "x": x,
      "y": y,
      "width": width,
      "height": height,
    };
    await methodChannel.invokeMethod<void>('bar', params);
  }

  Future<void> box({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    int linThickness = 2
  }) async {
    Map<String, dynamic> params = {
      "startX": startX,
      "startY": startY,
      "endX": endX,
      "endY": endY,
      "linThickness": linThickness,
    };
    await methodChannel.invokeMethod<void>('box', params);
  }

  Future<void> print(int copies) async {
    await methodChannel.invokeMethod<void>('print', {"copies": copies});
  }

  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

  int _getRotation(Rotation rotation) {
    switch(rotation) {
      case Rotation.r_0:
        return 0;
      case Rotation.r_90:
        return 90;
      case Rotation.r_180:
        return 180;
      case Rotation.r_270:
        return 270;
    }
  }

  String _getCodeType(BarCodeType codeType) {
    switch(codeType) {
      case BarCodeType.c_128:
        return "128";
      case BarCodeType.c_39:
        return "39";
      case BarCodeType.c_93:
        return "93";
      case BarCodeType.c_ITF:
        return "ITF";
      case BarCodeType.c_UPCA:
        return "UPCA";
      case BarCodeType.c_UPCE:
        return "UPCE";
      case BarCodeType.c_CODABAR:
        return "CODABAR";
      case BarCodeType.c_EAN8:
        return "EAN8";
      case BarCodeType.c_EAN13:
        return "EAN13";
    }
  }
}