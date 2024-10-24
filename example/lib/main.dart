import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';

import 'function_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _bluetoothPrintPlus = BluetoothPrintPlus.instance;
  bool connected = false;
  bool isReady = false;
  BluetoothDevice? _device;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  Future<void> initBluetooth() async {
    /// listen state
    _bluetoothPrintPlus.state.listen((state) {
      print('********** state change: $state **********');
      switch (state) {
        case BPPState.blueOn:
          isReady = true;
          break;
        case BPPState.blueOff:
          isReady = false;
          break;
        case BPPState.deviceConnected:
          setState(() {
            if (_device == null) return;
            connected = true;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionPage(_device!)));
          });
          break;
        case BPPState.deviceDisconnected:
          setState(() {
            _device = null;
            connected = false;
          });
          break;
      }
    });

    /// listen received data
    _bluetoothPrintPlus.receivedData.listen((data) {
      print('********** received data: $data **********');

      /// do something...
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BluetoothPrintPlus'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: StreamBuilder<List<BluetoothDevice>>(
              stream: _bluetoothPrintPlus.scanResults,
              initialData: const [],
              builder: (c, snapshot) => ListView(
                children: snapshot.data!
                    .map((d) => Container(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name ?? ''),
                                  Text(
                                    d.address ?? 'null',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const Divider(),
                                ],
                              )),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  _device = d;
                                  await _bluetoothPrintPlus.connect(d);
                                },
                                child: const Text("connect"),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            )),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                child: const Text("Search", style: TextStyle(fontSize: 16)),
                onPressed: () {
                  if (isReady == false) {
                    print("""
                      Please check if Bluetooth is turned on ???
                      Please check if Bluetooth is turned on ???
                      Please check if Bluetooth is turned on ???
                      """);
                    return;
                  }
                  _bluetoothPrintPlus.startScan(
                      timeout: const Duration(seconds: 30));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
