import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../services/notification_service.dart';
import './controllers/weighing_station_controller.dart';

// Import các widget con
import 'widgets/current_weight_card.dart';
import 'widgets/action_min_max.dart';
import 'widgets/scan_input_field.dart';
import 'widgets/weighing_table.dart';
import '../../widgets/main_app_bar.dart';

class WeighingStationScreen extends StatefulWidget {
  const WeighingStationScreen({super.key});

  @override
  State<WeighingStationScreen> createState() => _WeighingStationScreenState();
}

class _WeighingStationScreenState extends State<WeighingStationScreen> {
  // --- SỬ DỤNG DỊCH VỤ BLUETOOTH CHUNG ---
  final BluetoothService _bluetoothService = BluetoothService();
  late final WeighingStationController _controller;

  final TextEditingController _scanTextController = TextEditingController(); // CONTROLLER CHO SCAN INPUT FIELD

  void _onConnectionChange() {
    // 1. Kiểm tra xem màn hình còn "sống" (mounted)
    // 2. Và kiểm tra xem Bluetooth có bị ngắt (value == null)
    if (mounted && _bluetoothService.connectedDevice.value == null) {
      
      // 3. Chỉ hiện thông báo, KHÔNG chuyển trang
      NotificationService().showToast(
        context: context,
        message: 'Đã mất kết nối với cân Bluetooth!',
        type: ToastType.error, // Hộp thoại màu đỏ
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // --- KHỞI TẠO CONTROLLER ---
    _controller = WeighingStationController(bluetoothService: _bluetoothService);
    _bluetoothService.connectedDevice.addListener(_onConnectionChange);
    _controller.syncPendingData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanTextController.dispose(); // Hủy controller khi màn hình bị hủy
    _bluetoothService.connectedDevice.removeListener(_onConnectionChange);
    super.dispose();
  }


  Widget _buildWeighingTypeDropdown() {
    // Xác định màu sắc dựa trên loại cân
    final bool isNhap = _controller.selectedWeighingType == WeighingType.nhap;
    final Color backgroundColor = isNhap 
        ? const Color(0xFF4CAF50)  // Xanh lá cho Nhập
        : const Color(0xFF2196F3); // Xanh dương cho Xuất
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 115, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha:5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WeighingType>(
          value: _controller.selectedWeighingType,
          icon: const SizedBox.shrink(), // Xóa icon mũi tên
          dropdownColor: Colors.transparent, // Nền trong suốt
          
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          items: [
            DropdownMenuItem(
              value: WeighingType.nhap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Xanh lá cho Nhập
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Text('Cân Nhập', style: TextStyle(color: Colors.white, fontSize: 20)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_downward, color: Color.fromARGB(255, 238, 234, 9), size: 30),
                  ],
                ),
              ),
            ),
            DropdownMenuItem(
              value: WeighingType.xuat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3), // Xanh dương cho Xuất
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Text('Cân Xuất', style: TextStyle(color: Colors.white, fontSize: 20)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_upward,color: Color.fromARGB(255, 238, 9, 9), size: 30),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (WeighingType? newValue) {
            if (newValue != null) {
              _controller.updateWeighingType(newValue);
              setState(() {}); // Force rebuild để đổi màu
            }
          },
        ),
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
     appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN CAO SU XƯỞNG ĐẾ',
        bluetoothService: _bluetoothService,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại trang chủ',
          onPressed: () {
            // Logic cho nút Back cụ thể của màn hình này
            Navigator.of(context).pop();
          },
        ),
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
  // Xác định màu nền dựa trên loại cân
    final bool isNhap = _controller.selectedWeighingType == WeighingType.nhap;
    final Color pageBackgroundColor = isNhap
        ? const Color.fromARGB(134, 74, 207, 140)  // Xám nhạt cho Nhập
        : const Color.fromARGB(255, 173, 207, 241); // Xanh dương nhạt cho Xuất

    return Container(
      color: pageBackgroundColor, // Nền toàn trang
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height, // đảm bảo kéo dài đủ màn hình
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạm Cân',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
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
                          Row(
                            children: [
                              ActionBar(
                                selectedPercentage: _controller.selectedPercentage,
                                onPercentageChanged: _controller.updatePercentage,
                              ),
                              const SizedBox(width: 16),
                              _buildWeighingTypeDropdown(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ScanInputField(
                            controller: _scanTextController,
                            onScan: (code) =>
                                _controller.handleScan(context, code),
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<double>(
                            valueListenable: _bluetoothService.currentWeight,
                            builder: (context, currentWeight, child) {
                              final bool isInRange =
                                  (currentWeight >= _controller.minWeight) &&
                                      (currentWeight <= _controller.maxWeight) &&
                                      _controller.minWeight > 0;

                              final Color buttonColor = isInRange
                                  ? Colors.green
                                  : const Color(0xFFE8EAF6);
                              final Color textColor = isInRange
                                  ? Colors.white
                                  : Colors.indigo;

                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_controller.khoiLuongMe == 0.0) {
                                      NotificationService().showToast(
                                        context: context,
                                        message: 'Vui lòng scan mã để cân!',
                                        type: ToastType.info,
                                      );
                                      return;
                                    }

                                    final bool success =
                                        await _controller.completeCurrentWeighing(
                                      context,
                                      currentWeight,
                                    );

                                    if (success) {
                                      _scanTextController.clear();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: textColor,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                  child: const Text('Hoàn tất',
                                      style: TextStyle(fontSize: 30)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                WeighingTable(
                  records: _controller.records,
                  weighingType: _controller.selectedWeighingType,
                  activeOVNO: _controller.activeOVNO,
                  activeMemo: _controller.activeMemo,
                  totalTargetQty: _controller.activeTotalTargetQty,
                  totalNhap: _controller.activeTotalNhap,
                  totalXuat: _controller.activeTotalXuat,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}