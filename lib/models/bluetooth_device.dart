class BluetoothDevice {
  final String name;
  final String address;
  final int rssi;

  BluetoothDevice({required this.name, required this.address, required this.rssi});

  @override
  bool operator ==(Object other) => other is BluetoothDevice && address == other.address;

  @override
  int get hashCode => address.hashCode;
}