import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'enum_tool.dart';

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

  Future<void> image({
    required Uint8List image,
    Alignment alignment = Alignment.left,
  }) async {
    int align = EnumTool.getAlignment(alignment);
    Map<String, dynamic> params = {"image": image, "alignment": align};
    await methodChannel.invokeMethod<void>('image', params);
  }

  Future<void> newline() async {
    await methodChannel.invokeMethod<void>('newline');
  }

  Future<void> print({int feedLines = 4}) async {
    await methodChannel.invokeMethod<void>('print', {"feedLines": feedLines});
  }
}
