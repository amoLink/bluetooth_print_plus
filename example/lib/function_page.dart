
import 'package:bluetooth_print_plus/bluetooth_print_model.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/cpcl_command.dart';
import 'package:bluetooth_print_plus/esc_command.dart';
import 'package:bluetooth_print_plus/tsp_command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FunctionPage extends StatefulWidget {
  final BluetoothDevice device;
  const FunctionPage(this.device, {super.key});

  @override
  State<FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<FunctionPage> {
  final tscCommand = TscCommand();
  final cpclCommand = CpclCommand();
  final escCommand = EscCommand();
  int groupValue = 0;

  @override
  void dispose() {
    super.dispose();

    BluetoothPrintPlus.instance.disconnect();
    print("FunctionPage dispose");
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? ""),
      ),
      body: Column(
        children: [
          buildRadioGroupRowWidget(),
          const SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await tscCommand.cleanCommand();
                  await tscCommand.selfTest();
                  final cmd = await tscCommand.getCommand();
                  if (cmd == null) return;
                  BluetoothPrintPlus.instance.write(cmd);
                  print("getCommand $cmd");
                },
                child: const Text("selfTest")
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    final ByteData bytes = await rootBundle.load("assets/dithered-image.png");
                    final Uint8List image = bytes.buffer.asUint8List();
                    if (groupValue == 0) {
                      await tscCommand.cleanCommand();
                      await tscCommand.cls();
                      await tscCommand.size(width: 76, height: 130);
                      await tscCommand.image(image: image, x: 50, y: 60);
                      await tscCommand.print(1);
                      final cmd = await tscCommand.getCommand();
                      if (cmd == null) return;
                      BluetoothPrintPlus.instance.write(cmd);
                      print("get tsc Command $cmd");
                      return;
                    } else if(groupValue == 1) {
                      await cpclCommand.cleanCommand();
                      await cpclCommand.size(width: 76, height: 130);
                      await cpclCommand.image(image: image, x: 10, y: 10);
                      await cpclCommand.print();
                      final cmd = await cpclCommand.getCommand();
                      if (cmd == null) return;
                      BluetoothPrintPlus.instance.write(cmd);
                      print("get cpcl Command $cmd");
                    } else {
                      await escCommand.cleanCommand();
                      await escCommand.print();
                      await escCommand.image(image: image);
                      await escCommand.print();
                      final cmd = await escCommand.getCommand();
                      if (cmd == null) return;
                      BluetoothPrintPlus.instance.write(cmd);
                      print("get esc Command $cmd");
                    }

                  },
                  child: const Text("image")
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    await tscCommand.cleanCommand();
                    await tscCommand.size(width: 76, height: 130);
                    await tscCommand.cls();
                    await tscCommand.speed(8);
                    await tscCommand.density(8);
                    await tscCommand.text(
                      content: "莫听穿林打叶声，何妨吟啸且徐行。",
                      x: 10,
                      y: 10,
                    );
                    await tscCommand.text(
                      content: "竹杖芒鞋轻胜马，谁怕？",
                      x: 10,
                      y: 60,
                      xMulti: 2,
                      yMulti: 2
                    );
                    await tscCommand.text(
                      content: "一蓑烟雨任平生。",
                      x: 10,
                      y: 170,
                      xMulti: 3,
                      yMulti: 3
                    );
                    await tscCommand.qrCode(
                      // content: "料峭春风吹酒醒，微冷，山头斜照却相迎。",
                      content: "28938928",
                      x: 50,
                      y: 350,
                      cellWidth: 3
                    );
                    await tscCommand.qrCode(
                      // content: "回首向来萧瑟处，归去，也无风雨也无晴。",
                      content: "28938928",
                      x: 50,
                      y: 500,
                    );
                    await tscCommand.barCode(
                      content: "123456789",
                      x: 200,
                      y: 350,
                    );
                    await tscCommand.print(1);
                    final cmd = await tscCommand.getCommand();
                    if (cmd == null) return;
                    BluetoothPrintPlus.instance.write(cmd);
                    print("getCommand $cmd");
                  },
                  child: const Text("text/QR_code/barcode")
              ),
            ],
          )
        ],
      ),
    );
  }

  Row buildRadioGroupRowWidget() {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("command type"),
            Radio(
              value: 0,
              groupValue: groupValue,
              onChanged: (v) {
                setState(() {
                  groupValue = v!;
                });
              },
            ),
            const Text("tsc")
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              value: 1,
              groupValue: groupValue,
              onChanged: (v) {
                setState(() {
                  groupValue = v!;
                });
              },
            ),
            const Text("cpcl")
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              value: 2,
              groupValue: groupValue,
              onChanged: (v) {
                setState(() {
                  groupValue = v!;
                });
              },
            ),
            const Text("esc")
          ],
        ),
      ],
    );
  }
}