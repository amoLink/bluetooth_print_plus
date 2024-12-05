import 'package:flutter/services.dart';
import 'enum_tool.dart';

class TscCommand {
  TscCommand();

  final methodChannel = const MethodChannel('bluetooth_print_plus_tsc');

  /// Clean command buffer. This method must be called before calling any other method,
  /// otherwise the command buffer will be invalid.
  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  /// Self test. This method must be called after calling cleanCommand.
  ///
  /// The printer will print a self-test page.
  ///
  /// The self-test page will include the printer's model, firmware version, and
  /// other information.
  ///
  /// This method will block until the printer is ready to print.
  Future<void> selfTest() async {
    await methodChannel.invokeMethod<void>('selfTest');
  }

  /// Clear the printer's buffer.
  ///
  /// This method is used to clear the printer's buffer of any previously
  /// received data.
  ///
  /// This method will block until the printer is ready to print.
  Future<void> cls() async {
    await methodChannel.invokeMethod<void>('cls');
  }

  /// Sets the gap between labels in millimeters.
  ///
  /// [gap] is the gap between labels. It determines the space between
  /// consecutive printed labels. Ensure the printer supports the specified
  /// gap value to avoid any issues.
  Future<void> gap(int gap) async {
    Map<String, dynamic> params = {"gap": gap};
    await methodChannel.invokeMethod<void>('gap', params);
  }

  /// Sets the printing speed of the printer. The value is in the range [25, 250].
  ///
  /// The printing speed is in the range of 25 mm/s to 250 mm/s.
  ///
  /// The default printing speed is 100 mm/s.
  ///
  /// This method will block until the printing speed is changed.
  ///
  Future<void> speed(int speed) async {
    Map<String, dynamic> params = {"speed": speed};
    await methodChannel.invokeMethod<void>('speed', params);
  }

  /// Sets the print density of the printer.
  ///
  /// [density] is the density level to set for the printer's output. It
  /// determines how dark or light the printed output appears. Ensure the
  /// printer supports the specified density value to avoid any issues.
  ///
  /// This method will block until the printer's density is set.
  Future<void> density(int density) async {
    Map<String, dynamic> params = {"density": density};
    await methodChannel.invokeMethod<void>('density', params);
  }

  /// Sets the print area of the printer.
  ///
  /// [width] and [height] are the width and height of the print area in dots.
  /// If [width] and [height] are 0, the print area will be set to the full
  /// paper size.
  ///
  /// This method will block until the print area is set.
  Future<void> size({int width = 0, int height = 0}) async {
    Map<String, dynamic> params = {"width": width, "height": height};
    await methodChannel.invokeMethod<void>('size', params);
  }

  /// Prints a string of text on the printer.
  ///
  /// [content] is the text string to be printed.
  ///
  /// [x] and [y] are the coordinates of the top left corner of the text.
  /// Defaults to 0.
  ///
  /// [xMulti] and [yMulti] are the multiplication factors for the x and y
  /// coordinates. Defaults to 1.
  ///
  /// [rotation] is the rotation of the text. Defaults to [Rotation.r_0].
  ///
  /// This method will block until the text is printed.
  Future<void> text({
    required String content,
    int x = 0,
    int y = 0,
    int xMulti = 1,
    int yMulti = 1,
    Rotation rotation = Rotation.r_0,
  }) async {
    int rota = EnumTool.getRotation(rotation);
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

  /// Prints an image on the printer.
  ///
  /// [image] is the image data to be printed. It should be a [Uint8List] of the
  /// image data.
  ///
  /// [x] and [y] are the coordinates of the top left corner of the image.
  /// Defaults to 0.
  ///
  /// This method will block until the image is printed.
  Future<void> image({
    required Uint8List image,
    int x = 0,
    int y = 0,
  }) async {
    Map<String, dynamic> params = {"x": x, "y": y, "image": image};
    await methodChannel.invokeMethod<void>('image', params);
  }

  /// Prints a QR code on the printer.
  ///
  /// [content] is the content to be encoded in the QR code.
  ///
  /// [x] and [y] are the coordinates of the top left corner of the QR code.
  /// Defaults to 0.
  ///
  /// [cellWidth] is the width of each cell in the QR code. Valid range is from
  /// 1 to 16. Defaults to 6.
  ///
  /// [rotation] is the rotation of the QR code. Defaults to [Rotation.r_0].
  ///
  /// This method will block until the QR code is printed.
  Future<void> qrCode({
    required String content,
    int x = 0,
    int y = 0,
    int cellWidth = 6,
    Rotation rotation = Rotation.r_0,
  }) async {
    int rota = EnumTool.getRotation(rotation);
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "cellWidth": cellWidth,
      "rotation": rota
    };
    await methodChannel.invokeMethod<void>('qrCode', params);
  }

  /// Prints a 1D barcode on the printer.
  ///
  /// [content] is the content to be encoded in the barcode.
  ///
  /// [x] and [y] are the coordinates of the top left corner of the barcode.
  /// Defaults to 0.
  ///
  /// [codeType] is the type of the barcode. Defaults to [BarCodeType.c_128].
  ///
  /// [rotation] is the rotation of the barcode. Defaults to [Rotation.r_0].
  ///
  /// [height] is the height of the barcode. Valid range is from 1 to 255.
  /// Defaults to 100.
  ///
  /// [readable] is whether the barcode should be printed in human readable
  /// style. Defaults to true.
  ///
  /// [narrow] is the width of the narrow bar in the barcode. Valid range is
  /// from 1 to 16. Defaults to 2.
  ///
  /// [wide] is the width of the wide bar in the barcode. Valid range is from 1
  /// to 16. Defaults to 4.
  ///
  /// This method will block until the barcode is printed.
  Future<void> barCode(
      {required String content,
      int x = 0,
      int y = 0,
      BarCodeType codeType = BarCodeType.c_128,
      Rotation rotation = Rotation.r_0,
      int height = 100,
      bool readable = true,
      int narrow = 2,
      int wide = 4}) async {
    Map<String, dynamic> params = {
      "content": content,
      "x": x,
      "y": y,
      "codeType": EnumTool.getCodeType(codeType),
      "rotation": EnumTool.getRotation(rotation),
      "height": height,
      "readable": readable,
      "narrow": narrow,
      "wide": wide,
    };
    await methodChannel.invokeMethod<void>('barCode', params);
  }

  /// Draws a bar on the printer.
  ///
  /// [x] is the x-coordinate of the bar.
  ///
  /// [y] is the y-coordinate of the bar.
  ///
  /// [width] is the width of the bar.
  ///
  /// [height] is the height of the bar. Defaults to 2.
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

  /// Draws a box on the printer.
  ///
  /// [x] and [y] are the coordinates of the top left corner of the box.
  ///
  /// [endX] and [endY] are the coordinates of the bottom right corner of the box.
  ///
  /// [linThickness] is the thickness of the lines in the box. Defaults to 2.
  Future<void> box(
      {required int x,
      required int y,
      required int endX,
      required int endY,
      int linThickness = 2}) async {
    Map<String, dynamic> params = {
      "x": x,
      "y": y,
      "endX": endX,
      "endY": endY,
      "linThickness": linThickness,
    };
    await methodChannel.invokeMethod<void>('box', params);
  }

  /// Sends a print command to the printer with specified number of copies.
  ///
  /// This method tells the printer to print the current content of the
  /// printer with the specified number of copies. The method communicates
  /// with the printer through a method channel.
  ///
  /// - Parameters:
  ///   - copies: The number of copies of the content to print. Must be greater
  ///     than 0.
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> print(int copies) async {
    await methodChannel.invokeMethod<void>('print', {"copies": copies});
  }

  /// Gets the current command bytes from the printer.
  ///
  /// This method asks the printer for the current command bytes. The method
  /// communicates with the printer through a method channel.
  ///
  /// - Returns: A [Future] that completes with [Uint8List] of the command bytes.
  ///   If the printer did not return any command bytes, this method will return
  ///   `null`.
  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }
}
