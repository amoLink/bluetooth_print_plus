import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';

import 'function_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
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
  bool isBlueOn = false;
  BluetoothDevice? _device;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  Future<void> initBluetooth() async {
    /// listen isScanning
    _bluetoothPrintPlus.isScanning.listen((event) {
      print('********** isScanning: $event **********');
      if (mounted) {
        setState(() {});
      }
    });

    /// listen state
    _bluetoothPrintPlus.state.listen((state) {
      print('********** state change: $state **********');
      switch (state) {
        case BPPState.blueOn:
          isBlueOn = true;
          break;
        case BPPState.blueOff:
          isBlueOn = false;
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
                    .map((device) => Container(
                          padding:
                              EdgeInsets.only(left: 10, right: 10, bottom: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.name),
                                  Text(
                                    device.address,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Divider(),
                                ],
                              )),
                              SizedBox(
                                width: 10,
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  _device = device;
                                  await _bluetoothPrintPlus.connect(device);
                                },
                                child: const Text("connect"),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            )),
          ],
        ),
      ),
      floatingActionButton: buildScanButton(context),
    );
  }

  Widget buildScanButton(BuildContext context) {
    if (_bluetoothPrintPlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
          onPressed: onScanPressed,
          backgroundColor: Colors.green,
          child: Text("SCAN"));
    }
  }

  Future onScanPressed() async {
    try {
      if (isBlueOn == false) {
        print("""
          Please check if Bluetooth is turned on !!!
          Please check if Bluetooth is turned on !!!
          Please check if Bluetooth is turned on !!!
          """);
        return;
      }
      await _bluetoothPrintPlus.startScan(timeout: Duration(seconds: 10));
    } catch (e) {
      print("onScanPressed error: $e");
    }
  }

  Future onStopPressed() async {
    try {
      _bluetoothPrintPlus.stopScan();
    } catch (e) {
      print("onStopPressed error: $e");
    }
  }
}
