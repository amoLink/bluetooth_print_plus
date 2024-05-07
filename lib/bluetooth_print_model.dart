import 'package:json_annotation/json_annotation.dart';

part 'bluetooth_print_model.g.dart';

@JsonSerializable(includeIfNull: false)
/// BluetoothDevice
class BluetoothDevice {
  BluetoothDevice();

  /// printer name
  String? name;
  /// printer id
  String? address;
  /// type
  int? type = 0;
  /// connected ?
  bool? connected = false;

  /// BluetoothDevice obj from json
  factory BluetoothDevice.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDeviceFromJson(json);
  /// json to BluetoothDevice obj
  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);
}

