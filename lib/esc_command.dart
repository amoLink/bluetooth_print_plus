import 'package:flutter/services.dart';

import 'enum_tool.dart';

class EscCommand {
  final methodChannel = const MethodChannel('bluetooth_print_plus_esc');

  EscCommand();

  Future<void> cleanCommand() async {
    await methodChannel.invokeMethod<void>('cleanCommand');
  }

  Future<Uint8List?> getCommand() async {
    final command = await methodChannel.invokeMethod<Uint8List>('getCommand');
    return command;
  }

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

  /// image
  Future<void> image({
    required Uint8List image,
    Alignment alignment = Alignment.left,
  }) async {
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {"image": image, "alignment": align};
    await methodChannel.invokeMethod<void>('image', params);
  }

  /// newline
  Future<void> newline() async {
    await methodChannel.invokeMethod<void>('newline');
  }

  Future<void> cutPaper() async {
    await methodChannel.invokeMethod<void>('cutPaper');
  }

  /// add sound
  Future<void> sound({int number = 1, int time = 3}) async {
    Map<String, dynamic> params = {"number": number, "time": time};
    await methodChannel.invokeMethod<void>('sound', params);
  }

  /// print
  Future<void> print({int feedLines = 4}) async {
    await methodChannel.invokeMethod<void>('print', {"feedLines": feedLines});
  }
}
