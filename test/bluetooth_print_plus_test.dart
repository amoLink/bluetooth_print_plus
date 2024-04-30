// import 'package:flutter_test/flutter_test.dart';
// import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
// import 'package:bluetooth_print_plus/bluetooth_print_plus_platform_interface.dart';
// import 'package:bluetooth_print_plus/bluetooth_print_plus_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockBluetoothPrintPlusPlatform
//     with MockPlatformInterfaceMixin
//     implements BluetoothPrintPlusPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final BluetoothPrintPlusPlatform initialPlatform = BluetoothPrintPlusPlatform.instance;
//
//   test('$MethodChannelBluetoothPrintPlus is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelBluetoothPrintPlus>());
//   });
//
//   test('getPlatformVersion', () async {
//     BluetoothPrintPlus bluetoothPrintPlusPlugin = BluetoothPrintPlus();
//     MockBluetoothPrintPlusPlatform fakePlatform = MockBluetoothPrintPlusPlatform();
//     BluetoothPrintPlusPlatform.instance = fakePlatform;
//
//     expect(await bluetoothPrintPlusPlugin.getPlatformVersion(), '42');
//   });
// }
