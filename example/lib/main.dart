import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

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
  bool _connected = false;
  BluetoothDevice? _device;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  Future<void> initBluetooth() async {
    bool isConnected = await _bluetoothPrintPlus.isConnected ?? false;
    _bluetoothPrintPlus.state.listen((state) {
      print('********** cur device status: $state **********');
      switch (state) {
        case BluetoothPrintPlus.connected:
          setState(() {
            if (_device == null) return;
            _connected = true;
            _bluetoothPrintPlus.stopScan();
            Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => FunctionPage(_device!)));
          });
          break;
        case BluetoothPrintPlus.disconnected:
          setState(() {
            _device = null;
            _connected = false;
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
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
              initialData: [],
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
                                  _bluetoothPrintPlus.connect(d);
                                  _device = d;
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
                  _bluetoothPrintPlus.isAvailable;
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
