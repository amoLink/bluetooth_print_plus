/// BluetoothDevice
class BluetoothDevice {
  BluetoothDevice(this.name, this.address);

  /// printer name
  String name;

  /// printer id
  String address;

  /// type
  int type = 0;

  /// BluetoothDevice obj from json
  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(json['name'], json['address'])
      ..type = json['type'] as int;
  }

  /// BluetoothDevice obj to json
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'address': address,
      'type': type
    };
    return json;
  }
}
