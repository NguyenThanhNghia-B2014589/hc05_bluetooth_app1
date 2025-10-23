import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../services/notification_service.dart';
import './controllers/weighing_station_controller.dart';
import '../../models/bluetooth_device.dart';

// Import các widget con
import 'widgets/current_weight_card.dart';
import 'widgets/action_min_max.dart';
import 'widgets/scan_input_field.dart';
import 'widgets/weighing_table.dart';

class WeighingStationScreen extends StatefulWidget {
  const WeighingStationScreen({super.key});

  @override
  State<WeighingStationScreen> createState() => _WeighingStationScreenState();
}

class _WeighingStationScreenState extends State<WeighingStationScreen> {
  // --- SỬ DỤNG DỊCH VỤ BLUETOOTH CHUNG ---
  final BluetoothService _bluetoothService = BluetoothService();
  late final WeighingStationController _controller;
  BluetoothDevice? _lastConnectedDevice; // Biến để "nhớ" thiết bị cuối cùng kết nối

  @override
  void initState() {
    super.initState();
    // --- KHỞI TẠO CONTROLLER ---
    _controller = WeighingStationController(bluetoothService: _bluetoothService);

    _lastConnectedDevice = _bluetoothService.connectedDevice.value;
    
   //_bluetoothService.connectedDevice.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    //_bluetoothService.connectedDevice.removeListener(_onConnectionChange);
    _controller.dispose();
    super.dispose();
  }

  /*void _onConnectionChange() {
    if (_bluetoothService.connectedDevice.value == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/scan');
    }
  }*/

  Widget _buildWeighingTypeDropdown() {
  // (AnimatedBuilder đã lắng nghe _controller ở ngoài,
  // nên widget này sẽ tự build lại khi _controller.updateWeighingType)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WeighingType>(
          value: _controller.selectedWeighingType,
          // isExpanded: true, // <-- XÓA DÒNG NÀY
          icon: const Icon(Icons.import_export, color: Colors.blueAccent),
          items: const [
            DropdownMenuItem(
              value: WeighingType.nhap,
              child: Text('Cân Nhập'), // Đơn giản hóa text
            ),
            DropdownMenuItem(
              value: WeighingType.xuat,
              child: Text('Cân Xuất'), // Đơn giản hóa text
            ),
          ],
          onChanged: (WeighingType? newValue) {
            _controller.updateWeighingType(newValue);
          },
        ),
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        //automaticallyImplyLeading: false, // Tắt nút quay lại mặc định
        leading: IconButton(
         icon: const Icon(Icons.arrow_back), // Icon quay lại trang scan
          tooltip: 'Quay lại trang Scan',
          onPressed: () {
            // Đảm bảo ngắt kết nối trước khi quay lại
            _bluetoothService.disconnect(); 
            Navigator.of(context).pushReplacementNamed('/scan');
          },
        ),
        actions: [
          //const Icon(Icons.person, color: Colors.black54),
          const SizedBox(width: 8),
          //Text(_bluetoothService.connectedDevice.value?.name ?? 'HC-05', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          
          ValueListenableBuilder<BluetoothDevice?>(
            valueListenable: _bluetoothService.connectedDevice,
            builder: (context, device, child) {
              
              // 1. Cập nhật biến "nhớ" nếu đang kết nối
              if (device != null) {
                _lastConnectedDevice = device;
              }
              final isConnected = (device != null);

              if (isConnected) {
                // 2. TRẠNG THÁI: ĐANG KẾT NỐI (MÀU XANH, NGẮT KẾT NỐI)
                return Row(
                  children: [
                    Text(device.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.link),
                      color: Colors.green.shade700,
                      tooltip: 'Ngắt kết nối',
                      onPressed: () {
                        _bluetoothService.disconnect();
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
                // 3. TRẠNG THÁI: NGẮT KẾT NỐI (MÀU ĐỎ, KẾT NỐI LẠI)
                return Row(
                  children: [
                    const Text('Chưa kết nối', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.link_off),
                      color: Colors.red,
                      tooltip: 'Kết nối lại',
                      onPressed: () {
                          // 4. KIỂM TRA BIẾN "NHỚ"
                          if (_lastConnectedDevice != null) {
                            NotificationService().showToast(
                              context: context,
                              message: 'Đang kết nối lại...',
                              type: ToastType.info
                            );
                            _bluetoothService.connectToDevice(_lastConnectedDevice!);
                          } else {
                            NotificationService().showToast(
                              context: context,
                              message: 'Không thể kết nối lại, vui lòng quay lại trang Scan.',
                              type: ToastType.error
                            );
                          }
                        },
                      ),
                  ],
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Hàm _buildLayout bây giờ nằm bên trong builder
              return _buildLayout();
            },
          );
        },
      ),
    );
  }

  // Widget layout chính
  Widget _buildLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạm Cân', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột bên trái
              Expanded(
                flex: 2,
                child: CurrentWeightCard(
                  bluetoothService: _bluetoothService,
                  minWeight: _controller.minWeight,     
                  maxWeight: _controller.maxWeight,     
                  khoiLuongMe: _controller.khoiLuongMe,
                ),
              ),
              const SizedBox(width: 24),
              // Cột bên phải
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    ActionBar(
                      selectedPercentage: _controller.selectedPercentage,
                      minWeight: _controller.minWeight,
                      maxWeight: _controller.maxWeight,
                      onPercentageChanged: _controller.updatePercentage,
                    ), // << WIDGET CHO ACTION BAR

                    const SizedBox(height: 20),
                    ScanInputField(onScan: (code) => _controller.handleScan(context, code)), // WIDGET SCAN
                    const SizedBox(height: 20),
                    Row(
                        children: [
                              // 1. Dropdown (giờ đã nhỏ lại)
                              _buildWeighingTypeDropdown(), 
                              
                              const SizedBox(width: 16), // Khoảng cách giữa 2 widget
                              
                              // 2. Nút Hoàn Tất (bọc trong Expanded)
                              Expanded(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _bluetoothService.currentWeight,
                                  builder: (context, currentWeight, child) {
                                    final bool isInRange = (currentWeight >= _controller.minWeight) &&
                                        (currentWeight <= _controller.maxWeight) &&
                                        _controller.minWeight > 0;
                                    
                                    final Color buttonColor = isInRange ? Colors.green : const Color(0xFFE8EAF6);
                                    final Color textColor = isInRange ? Colors.white : Colors.indigo;

                                    return ElevatedButton(
                                      onPressed: () {
                                        // ... (Toàn bộ logic onPressed của bạn giữ nguyên)
                                        if (_controller.khoiLuongMe == 0.0) {
                                          NotificationService().showToast(
                                            context: context,
                                            message: 'Vui lòng scan mã để cân!',
                                            type: ToastType.info,
                                          );
                                          return; 
                                        }
                                        final bool success = _controller.completeCurrentWeighing(currentWeight);
                                        if (success) {
                                          NotificationService().showToast(
                                            context: context,
                                            message: 'Cân hoàn tất!',
                                            type: ToastType.success,
                                          );
                                        } else {
                                          NotificationService().showToast(
                                            context: context,
                                            message: 'Lỗi cân: Trọng lượng không nằm trong phạm vi cho phép!',
                                            type: ToastType.error,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        foregroundColor: textColor,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        // Thêm dòng này để nút lấp đầy Row
                                        minimumSize: const Size(double.infinity, 48), // 48 là chiều cao ~
                                      ),
                                      child: const Text('Hoàn tất'),
                                    );
                                  },
                                ),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          WeighingTable(records: _controller.records), // Bảng cân
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}