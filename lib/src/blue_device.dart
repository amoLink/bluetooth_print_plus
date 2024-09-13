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
  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice()
      ..name = json['name'] as String?
      ..address = json['address'] as String?
      ..type = json['type'] as int?
      ..connected = json['connected'] as bool?;
  }

  /// json to BluetoothDevice obj
  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{};

    void writeNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    writeNotNull('name', name);
    writeNotNull('address', address);
    writeNotNull('type', type);
    writeNotNull('connected', connected);
    return val;
  }
}
