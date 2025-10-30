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

  @override
  void initState() {
    super.initState();
    // --- KHỞI TẠO CONTROLLER ---
    _controller = WeighingStationController(bluetoothService: _bluetoothService);

  }

  @override
  void dispose() {
    _controller.dispose();
    _scanTextController.dispose(); // Hủy controller khi màn hình bị hủy
    super.dispose();
  }


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
     appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN CAO SU XƯỞNG ĐẾ',
        bluetoothService: _bluetoothService,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại trang chủ',
          onPressed: () {
            // Logic cho nút Back cụ thể của màn hình này
            _bluetoothService.disconnect();
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
                    ScanInputField(
                      controller: _scanTextController, // SỬ DỤNG CONTROLLER Ở ĐÂY
                      onScan: (code) => _controller.handleScan(context, code)), // WIDGET SCAN
                    const SizedBox(height: 20),
                    Row(
                        children: [
                              // Dropdown
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
                                          _scanTextController.clear(); // Xóa text khi hoàn tất
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
          // Bảng cân
          WeighingTable(
          records: _controller.records,
          weighingType: _controller.selectedWeighingType, // <-- TRUYỀN TYPE VÀO
          activeOVNO: _controller.activeOVNO,
          activeMemo: _controller.activeMemo,
        ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}