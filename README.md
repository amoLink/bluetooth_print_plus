# Bluetooth Print Plus

<span>
  <a href="https://pub.dartlang.org/packages/bluetooth_print_plus">
    <img src="https://img.shields.io/pub/v/bluetooth_print_plus.svg" alt="pub package">
  </a>
  <a href="https://github.com/amoLink/bluetooth_print_plus">
    <img src="https://img.shields.io/github/stars/amoLink/bluetooth_print_plus?logo=github&style=flat-square" alt="GitHub stars">
  </a>
  <a href="https://github.com/amoLink/bluetooth_print_plus">
    <img src="https://img.shields.io/github/forks/amoLink/bluetooth_print_plus?logo=github&style=flat-square" alt="GitHub forks">
  </a>
  <a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=srMhoE9RiFhIrhDoJB_jZCsaTvw09KaD&authKey=k4fAypkX3gSG7REanSfi0OZCXJxprJdnZ1y2BU2QAMbgOt0T%2F1hIr%2BikbO3kQPJc&noverify=0&group_code=904457621">
    <img src="https://github.com/amoLink/bluetooth_print_plus/blob/main/img/qq_group.png?raw=true" alt="qq_group" title="qq_group">
  </a>
  <a href="https://t.me/+a7KAkNjHFS81MGNi">
    <img src="https://github.com/amoLink/bluetooth_print_plus/blob/main/img/tg_group.png?raw=true" alt="tg_group" title="tg_group">
  </a>
</span>

## Introduction

Bluetooth Print Plus is a Bluetooth plugin used to print thermal printers in [Flutter](https://flutter.dev), a new mobile SDK to help developers build bluetooth thermal printer apps for iOS and Android.

<strong>
  <span style="color: red;">Important, important, important.</span> First, you need to run the demo to confirm the printer command type ! ! !
</strong>
<strong>
  now support <span style="color: green;">tspl/tsc、cpcl、esc pos.</span> 
  If this plugin is helpful to you, please give it a like, Thanks.
</strong>

## Buy Me A Coffee/请我喝杯咖啡

<div>
    <img src="https://github.com/amoLink/bluetooth_print_plus/blob/main/buy_me_a_coffee.png?raw=true" height="200px">
</div>

## Plan

| Version | plan                                          |
| ------- | --------------------------------------------- |
| 1.1.x   | blue and tsc command, esc print image command |
| 1.5.x   | support cpcl command                          |
| 2.x.x   | improve esc command                           |
| 3.x.x   | support zpl command                           |

## Features

|            |      Android       |        iOS         | Description                                            |
| :--------- | :----------------: | :----------------: | :----------------------------------------------------- |
| scan       | :white_check_mark: | :white_check_mark: | Starts a scan for Bluetooth Low Energy devices.        |
| connect    | :white_check_mark: | :white_check_mark: | Establishes a connection to the device.                |
| disconnect | :white_check_mark: | :white_check_mark: | Cancels an active or pending connection to the device. |
| state      | :white_check_mark: | :white_check_mark: | Stream of state changes for the Bluetooth Device.      |

## Usage

[Example](https://github.com/)

### To use this plugin :

- add the dependency to your [pubspec.yaml](https://github.com/amoLink/bluetooth_print_plus/blob/main/pubspec.yaml) file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  bluetooth_print_plus: ^2.4.5
```

### Add permissions for Bluetooth

---

We need to add the permission to use Bluetooth and access location:

#### **Android**

In the **android/app/src/main/AndroidManifest.xml** let’s add:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

#### **IOS**

In the **ios/Runner/Info.plist** let’s add:

```dart
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need BLE permission</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need BLE permission</string>
```

### import

```dart
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
```

### BluetoothPrintPlus useful property

```dart
BluetoothPrintPlus.isBlueOn;
BluetoothPrintPlus.isScanning;
BluetoothPrintPlus.isConnected;
```

### listen

---

```dart
late StreamSubscription<bool> _isScanningSubscription;
late StreamSubscription<BlueState> _blueStateSubscription;
late StreamSubscription<ConnectState> _connectStateSubscription;
late StreamSubscription<Uint8List> _receivedDataSubscription;
late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;
late List<BluetoothDevice> _scanResults;
```

- **scan results**

```dart
/// listen scanResults
_scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((event) {
  if (mounted) {
    setState(() {
      _scanResults = event;
    });
  }
});
```

- **state**

```dart
/// listen isScanning
_isScanningSubscription = BluetoothPrintPlus.isScanning.listen((event) {
  print('********** isScanning: $event **********');
  if (mounted) {
    setState(() {});
  }
});

/// listen blue state
_blueStateSubscription = BluetoothPrintPlus.blueState.listen((event) {
  print('********** blueState change: $event **********');
  /// blue state changed, do something...
});

/// listen connect state
_blueStateSubscription = _BluetoothPrintPlus.connectState.listen((event) {
  print('********** connectState change: $event **********');
  /// connect state changed, do something...
});
```

- **received Data**

```dart
_BluetoothPrintPlus.receivedData.listen((data) {
  print('********** received data: $data **********');
  /// received data, do something...
});
```

### scan

---

```dart
// begin scan
await BluetoothPrintPlus.startScan(timeout: Duration(seconds: 10));

// get devices
_scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((event) {
  if (mounted) {
    setState(() {
      _scanResults = event;
    });
  }
});
```

### connect

---

```dart
await BluetoothPrintPlus.connect(_device);
```

### disconnect

---

```dart
await BluetoothPrintPlus.disconnect();
```

### print/write

---

```dart
final ByteData bytes = await rootBundle.load("assets/dithered-image.png");

/// write tsc command, for example:
final Uint8List image = bytes.buffer.asUint8List();
await tscCommand.cleanCommand();
await tscCommand.size(width: 76, height: 130);
await tscCommand.cls(); // most after size
await tscCommand.image(image: image, x: 50, y: 60);
await tscCommand.print(1);
final cmd = await tscCommand.getCommand();
if (cmd == null) return;
BluetoothPrintPlus.write(cmd);

/// write cpcl command, for example:
await cpclCommand.cleanCommand();
await cpclCommand.size(width: 76 * 8, height: 76 * 8);
await cpclCommand.image(image: image, x: 10, y: 10);
await cpclCommand.print();
final cmd = await cpclCommand.getCommand();
if (cmd == null) return;
BluetoothPrintPlus.write(cmd);

/// write esc command, for example:
await escCommand.cleanCommand();
await escCommand.print();
await escCommand.image(image: image);
await escCommand.print();
final cmd = await escCommand.getCommand();
if (cmd == null) return;
BluetoothPrintPlus.write(cmd);
```

### Cancel Subscription

```dart
@override
void dispose() {
  super.dispose();
  _isScanningSubscription.cancel();
  _blueStateSubscription.cancel();
  _connectStateSubscription.cancel();
  _receivedDataSubscription.cancel();
  _scanResultsSubscription.cancel();
  _scanResults.clear();
  _device = null;
}
```

## Troubleshooting

#### error:'State restoration of CBCentralManager is only allowed for applications that have specified the "bluetooth-central" background mode'

info.plist add:

```
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Allow App use bluetooth?</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Allow App use bluetooth?</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
</array>
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/amoLink/bluetooth_print_plus.svg?variant=light)](https://starchart.cc/amoLink/bluetooth_print_plus)
