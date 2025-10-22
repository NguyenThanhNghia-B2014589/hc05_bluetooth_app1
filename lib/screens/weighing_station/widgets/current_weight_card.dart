import 'package:flutter/material.dart';
import '../../../services/bluetooth_service.dart';

class CurrentWeightCard extends StatelessWidget {
  final BluetoothService bluetoothService;
  final double minWeight;     // <-- GIÁ TRỊ MỚI
  final double maxWeight;     // <-- GIÁ TRỊ MỚI
  final double khoiLuongMe; // <-- GIÁ TRỊ MỚI (Khối lượng mục tiêu)

  const CurrentWeightCard({
    super.key,
    required this.bluetoothService,
    required this.minWeight,
    required this.maxWeight,
    required this.khoiLuongMe, // Phải truyền khối lượng mẻ vào đây
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        
        // **QUAN TRỌNG:**
        // Bọc TOÀN BỘ Column bằng ValueListenableBuilder 
        // để cả thanh % và màu sắc đều được cập nhật khi
        // currentWeight thay đổi.
        child: ValueListenableBuilder<double>(
          valueListenable: bluetoothService.currentWeight,
          builder: (context, currentWeight, child) {
            
            // --- BẮT ĐẦU LOGIC TÍNH TOÁN ---

            // 1. Kiểm tra xem có nằm trong phạm vi không
            final bool isInRange = (currentWeight >= minWeight) && (currentWeight <= maxWeight);

            // 2. Quyết định màu sắc
            final Color statusColor = isInRange ? Colors.green : Colors.red;

            // 3. Tính toán % chênh lệch so với khối lượng mẻ
            // (Phải kiểm tra khoiLuongMe != 0 để tránh lỗi chia cho 0)
            final double deviationPercent = (khoiLuongMe == 0)
                ? 0
                : ((currentWeight - khoiLuongMe) / khoiLuongMe) * 100;

            // Định dạng chuỗi hiển thị % (thêm dấu '+' nếu là số dương)
            final String deviationString =
                '${deviationPercent > 0 ? '+' : ''}${deviationPercent.toStringAsFixed(1)}%';

            // --- KẾT THÚC LOGIC TÍNH TOÁN ---

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trọng lượng hiện tại', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(3), // Hiển thị cân nặng
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('Kg', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),

                // --- CẬP NHẬT GIAO DIỆN ĐỘNG ---
                Text(
                  'Chênh lệch: $deviationString', // Hiển thị % động
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor, // Đổi màu chữ theo trạng thái
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 1.0, // Luôn đầy thanh, chỉ đổi màu
                  color: statusColor, // Đổi màu thanh theo trạng thái
                  backgroundColor: statusColor.withValues(alpha: 0.5), // Màu nền mờ
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}