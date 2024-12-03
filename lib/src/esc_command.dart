import 'package:flutter/services.dart';

import 'enum_tool.dart';

class EscCommand {
  EscCommand();

  final methodChannel = const MethodChannel('bluetooth_print_plus_esc');

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

  /// Sends a text command to the printer with specified parameters.
  ///
  /// This method allows you to print text on the printer with various styles
  /// and alignments. You can specify the content of the text, its alignment,
  /// style, and font size. The method communicates with the printer through
  /// a method channel.
  ///
  /// - Parameters:
  ///   - content: The text content to be printed.
  ///   - alignment: The alignment of the text. Defaults to [Alignment.left].
  ///   - style: The style of the text. Can be normal, bold, underline, or
  ///     both bold and underline. Defaults to [EscTextStyle.default_].
  ///   - fontSize: The font size of the text. Options range from default
  ///     to size 7. Defaults to [EscFontSize.default_].
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> text(
      {required String content,
      Alignment alignment = Alignment.left,
      EscTextStyle style = EscTextStyle.default_,
      EscFontSize fontSize = EscFontSize.default_}) async {
    int printMode = EnumTool.getEscTextStyle(style);
    int size = EnumTool.getEscFontSize(fontSize);
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {
      "content": content,
      "alignment": align,
      "printMode": printMode,
      "size": size
    };
    await methodChannel.invokeMethod<void>('text', params);
  }

  /// Sends a Code 128 command to the printer with specified parameters.
  ///
  /// This method allows you to print a Code 128 barcode on the printer with
  /// various styles and alignments. You can specify the content of the barcode,
  /// its alignment, its width and height, and whether to print the human
  /// readable interpretation (HRI) of the barcode. The method communicates with
  /// the printer through a method channel.
  ///
  /// - Parameters:
  ///   - content: The content of the barcode to be printed.
  ///   - width: The width of the barcode. Defaults to 2.
  ///   - height: The height of the barcode. Defaults to 60.
  ///   - alignment: The alignment of the barcode. Defaults to [Alignment.left].
  ///   - hriPosition: The position of the human readable interpretation of the
  ///     barcode. Options are [HriPosition.none], [HriPosition.above],
  ///     [HriPosition.below], and [HriPosition.aboveAndBelow]. Defaults to
  ///     [HriPosition.below].
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> code128(
      {required String content,
      int width = 2,
      int height = 60,
      Alignment alignment = Alignment.left,
      HriPosition hriPosition = HriPosition.below}) async {
    int hri = EnumTool.getHri(hriPosition);
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {
      "content": content,
      "alignment": align,
      "width": width,
      "height": height,
      "hri": hri
    };
    await methodChannel.invokeMethod<void>('code128', params);
  }

  /// Sends a QR code command to the printer with specified parameters.
  ///
  /// This method allows you to print a QR code on the printer with various
  /// alignments and sizes. You can specify the content of the QR code, its
  /// alignment, and its size. The method communicates with the printer
  /// through a method channel.
  ///
  /// - Parameters:
  ///   - content: The content to be encoded in the QR code.
  ///   - size: The size of the QR code. Valid range is from 1 to 16.
  ///     Defaults to 3.
  ///   - alignment: The alignment of the QR code on the printout.
  ///     Defaults to [Alignment.left].
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> qrCode({
    required String content,
    int size = 3,

    /// size range: 1~16
    Alignment alignment = Alignment.left,
  }) async {
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {
      "content": content,
      "size": size,
      "alignment": align,
    };
    await methodChannel.invokeMethod<void>('qrCode', params);
  }

  /// Sends an image command to the printer with specified parameters.
  ///
  /// This method allows you to print an image on the printer with various
  /// alignments. You can specify the image data and its alignment. The method
  /// communicates with the printer through a method channel.
  ///
  /// - Parameters:
  ///   - image: The image data.
  ///   - alignment: The alignment of the image on the printout.
  ///     Defaults to [Alignment.left].
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> image({
    required Uint8List image,
    Alignment alignment = Alignment.left,
  }) async {
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {"image": image, "alignment": align};
    await methodChannel.invokeMethod<void>('image', params);
  }

  /// Sends a newline command to the printer.
  ///
  /// This method sends a newline command to the printer. It is used to move the
  /// print head to the next line. The method communicates with the printer
  /// through a method channel.
  ///
  Future<void> newline() async {
    await methodChannel.invokeMethod<void>('newline');
  }

  /// Cuts the paper after printing. This method is used to cut the paper after
  /// printing and is only supported by some printers. The method communicates
  /// with the printer through a method channel.
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> cutPaper() async {
    await methodChannel.invokeMethod<void>('cutPaper');
  }

  /// Sends a sound command to the printer.
  ///
  /// This method triggers the printer to make a sound. The sound can be customized
  /// by specifying the number of beeps and the duration of each beep.
  /// The method communicates with the printer through a method channel.
  ///
  /// - Parameters:
  ///   - number: The number of times the printer beeps. Defaults to 1.
  ///   - time: The duration of each beep in units. Defaults to 3.
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> sound({int number = 1, int time = 3}) async {
    Map<String, dynamic> params = {"number": number, "time": time};
    await methodChannel.invokeMethod<void>('sound', params);
  }

  /// Prints the current buffer and feeds the paper by the specified number of
  /// lines. The method communicates with the printer through a method channel.
  ///
  /// - Parameters:
  ///   - feedLines: The number of lines to feed the paper. Defaults to 4.
  ///
  /// - Returns: A [Future] that completes when the command has been sent.
  Future<void> print({int feedLines = 4}) async {
    await methodChannel.invokeMethod<void>('print', {"feedLines": feedLines});
  }
}
