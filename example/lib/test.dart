import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';

void test() async {
  final tscCommand = TscCommand();
  await tscCommand.cls();
  await tscCommand.size(width: 76, height: 130);
  await tscCommand.text(
      content: "文本文本...",
      x: 10,
      y: 20,
      xMulti: 2,
      yMulti: 3,
      rotation: Rotation.r_180);

  final ByteData bytes = await rootBundle.load("assets/art5043800863.jpg");
  final Uint8List image = bytes.buffer.asUint8List();
  await tscCommand.image(image: image, x: 50, y: 60);

  final cmd = await tscCommand.getCommand();

  print("getCommand $cmd");
}
