import 'package:flutter/services.dart';

import 'enum_tool.dart';

class CpclCommand {
  CpclCommand();

  final methodChannel = const MethodChannel('bluetooth_print_plus_cpcl');

  /// Clean command buffer. This method must be called before calling any other method,
  /// otherwise the command buffer will be invalid.
  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  /// Get the current command buffer. If the command buffer is empty, return null.
  ///
  /// This method can be used to get the command buffer that has been set by other methods, such as [text], [image], [code128], etc.
  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

  /// Set the size of the paper.
  ///
  /// [width] and [height] are the width and height of the paper in dots.
  /// [copies] is the number of copies to print. Defaults to 1.
  ///
  /// This method must be called before calling any other method,
  /// otherwise the command buffer will be invalid.
  Future<void> size({required width, required height, int copies = 1}) async {
    Map<String, dynamic> params = {
      "width": width,
      "height": height,
      "copies": copies
    };
    await methodChannel.invokeMethod<void>('size', params);
  }

  /// Print an image on the printer.
  ///
  /// [image] is the image data. It should be a [Uint8List] of the image data.
  /// [x] and [y] are the coordinates of the top left corner of the image.
  /// Defaults to 0.
  Future<void> image({
    required Uint8List image,
    int x = 0,
    int y = 0,
  }) async {
    Map<String, dynamic> params = {"x": x, "y": y, "image": image};
    await methodChannel.invokeMethod<void>('image', params);
  }

  /// Print a text on the printer.
  ///
  /// [content] is the text content to be printed.
  /// [size] Font size identification. Defaults to 0.
  /// [x] and [y] are the coordinates of the top left corner of the text.
  /// Defaults to 0.
  /// [xMulti] and [yMulti] are the multiplication factors for the x and y
  /// coordinates. Defaults to 1.
  /// [rotation] is the rotation of the text. Defaults to [Rotation.r_0].
  /// [bold] is whether the text should be printed in bold style. Defaults to
  /// false.
  Future<void> text({
    required String content,
    int size = 0,
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
      "size": size,
      "x": x,
      "y": y,
      "xMulti": xMulti,
      "yMulti": yMulti,
      "rotation": rota,
      "bold": bold,
    };
    await methodChannel.invokeMethod<void>('text', params);
  }

  /// Print a QR code on the printer.
  ///
  /// [content] is the content of the QR code.
  /// [x] and [y] are the coordinates of the top left corner of the QR code.
  /// Defaults to 0.
  /// [width] is the width of the QR code. Defaults to 6. Range from 1 to 32.
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
      "width": width,
    };
    await methodChannel.invokeMethod<void>('qrCode', params);
  }

  /// Print a bar code on the printer.
  ///
  /// [content] is the content of the bar code.
  /// [x] and [y] are the coordinates of the top left corner of the bar code.
  /// Defaults to 0.
  /// [width] is the width of the bar code. Defaults to 4. Range from 1 to 6.
  /// [height] is the height of the bar code. Defaults to 100. Range from 1 to 255.
  /// [vertical] is a boolean indicating whether the bar code should be printed
  /// vertically. Defaults to false.
  /// [codeType] is the type of the bar code. Defaults to [BarCodeType.c_128].
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

  /// Draw a line on the printer.
  ///
  /// [x] and [y] are the coordinates of the start of the line.
  /// [endX] and [endY] are the coordinates of the end of the line.
  /// [width] is the width of the line. Defaults to 2. Range from 1 to 6.
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
      "endY": endY,
      "width": width,
    };
    await methodChannel.invokeMethod<void>('line', params);
  }

  /// Prints the current buffer and feeds the paper by the specified number of
  /// lines. The method communicates with the printer through a method channel.
  Future<void> print() async {
    await methodChannel.invokeMethod<void>('print');
  }

  // After printing is complete, locate it at the top of the next page.
  Future<void> form() async {
    await methodChannel.invokeMethod<void>('form');
  }
}
