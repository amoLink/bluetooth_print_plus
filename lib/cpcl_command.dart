import 'package:flutter/services.dart';

import 'enum_tool.dart';

class CpclCommand {
  final methodChannel = const MethodChannel('bluetooth_print_plus_cpcl');

  CpclCommand();

  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

  Future<void> size({required width, required height, int copies = 1}) async {
    Map<String, dynamic> params = {
      "width": width,
      "height": height,
      "copies": copies
    };
    await methodChannel.invokeMethod<void>('size', params);
  }

  Future<void> image({
    required Uint8List image,
    int x = 0,
    int y = 0,
  }) async {
    Map<String, dynamic> params = {"x": x, "y": y, "image": image};
    await methodChannel.invokeMethod<void>('image', params);
  }

  Future<void> text({
    required String content,
    int x = 0,
    int y = 0,
    int xMulti = 1,
    int yMulti = 1,
    Rotation rotation = Rotation.r_0,
    bool bold = false,
  }) async {
    int rota = EnumTool.getRotation(rotation);
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "xMulti": xMulti,
      "yMulti": yMulti,
      "rotation": rota,
      "bold": bold,
    };
    await methodChannel.invokeMethod<void>('text', params);
  }

  Future<void> qrCode({
    required String content,
    int x = 0,
    int y = 0,
    int width = 6, // 1-32
  }) async {
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "cellWidth": width,
    };
    await methodChannel.invokeMethod<void>('qrCode', params);
  }

  Future<void> barCode({
    required String content,
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 100,
    bool vertical = false,
    BarCodeType codeType = BarCodeType.c_128,
  }) async {
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "width": width,
      "height": height,
      "vertical": vertical,
      "codeType": EnumTool.getCodeType(codeType),
    };
    await methodChannel.invokeMethod<void>('barCode', params);
  }

  Future<void> line(
      {required int x,
      required int y,
      required int endX,
      required int endY,
      int width = 2}) async {
    Map<String, dynamic> params = {
      "x": x,
      "y": y,
      "endX": endX,
      "endXY": endY,
      "width": width,
    };
    await methodChannel.invokeMethod<void>('line', params);
  }

  Future<void> print() async {
    await methodChannel.invokeMethod<void>('print');
  }
}
