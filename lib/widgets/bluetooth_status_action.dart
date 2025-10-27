import 'package:flutter/material.dart';
import '../models/bluetooth_device.dart'; 
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';

class BluetoothStatusAction extends StatelessWidget {
  final BluetoothService bluetoothService;

  const BluetoothStatusAction({super.key, required this.bluetoothService});

  @override
  Widget build(BuildContext context) {
    // Đây chính là code ValueListenableBuilder từ AppBar cũ của bạn
    return ValueListenableBuilder<BluetoothDevice?>(
      valueListenable: bluetoothService.connectedDevice,
      builder: (context, device, child) {
        final isConnected = (device != null);

        if (isConnected) {
          // TRẠNG THÁI: ĐANG KẾT NỐI (MÀU XANH)
          return Row(
            children: [
              Text(
                device.name, // Lỗi "getter 'name' isn't defined" sẽ hết sau khi bạn import
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.link, size: 30.0,),
                color: Colors.green.shade700,
                tooltip: 'Ngắt kết nối',
                onPressed: () {
                  bluetoothService.disconnect();
                  NotificationService().showToast(
                    context: context,
                    message: 'Đã ngắt kết nối!',
                    type: ToastType.info,
                  );
                },
              ),
            ],
          );
        } else {
          // TRẠNG THÁI: NGẮT KẾT NỐI (MÀU ĐỎ)
          return Row(
            children: [
              const Text('Chưa kết nối',
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.link_off,size: 30.0,),
                color: Colors.red,
                tooltip: 'Kết nối lại',
                onPressed: () {
                  // Lấy thiết bị cuối từ service
                  if (bluetoothService.lastConnectedDevice != null) {
                    NotificationService().showToast(
                        context: context,
                        message: 'Đang kết nối lại...',
                        type: ToastType.info);
                    bluetoothService
                        .connectToDevice(bluetoothService.lastConnectedDevice!);
                  } else {
                    NotificationService().showToast(
                      context: context,
                      message: 'Không thể kết nối lại, vui lòng quay lại trang Scan.',
                      type: ToastType.error,
                    );
                  }
                },
              ),
            ],
          );
        }
      },
    );
  }
}