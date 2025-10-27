import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Dữ liệu mẫu
class _ChartData {
  final int hour;
  final double nhap;
  final double xuat;
  const _ChartData(this.hour, this.nhap, this.xuat);
}

class HourlyWeighingChart extends StatelessWidget {
  const HourlyWeighingChart({super.key});

  // Màu sắc
  static const Color colorNhap = Color(0xFF81C784); // Xanh lá
  static const Color colorXuat = Color(0xFFE57373); // Đỏ

  // Dữ liệu mock-up (giống trong hình)
  final List<_ChartData> _data = const [
    _ChartData(7, 1800, 0),
    _ChartData(8, 1500, 0),
    _ChartData(9, 750, 550), // 750 + 550 = 1300
    _ChartData(10, 1800, 0),
    _ChartData(11, 0, 0), // Giờ nghỉ
    _ChartData(12, 500, 500), // 500 + 500 = 1000
    _ChartData(13, 550, 550), // 550 + 550 = 1100
    _ChartData(14, 0, 0), // Giờ nghỉ
    _ChartData(15, 1400, 0),
    _ChartData(16, 0, 0), // Giờ nghỉ
    _ChartData(17, 900, 500), // 900 + 500 = 1400
  ];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              // 1. Căn chỉnh
              alignment: BarChartAlignment.spaceAround,
              
              // 2. Trục Y (Trái)
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                
                // Trục Y
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return _bottomTitle('0', );
                      if (value == 450) return _bottomTitle('450', );
                      if (value == 900) return _bottomTitle('900', );
                      if (value == 1350) return _bottomTitle('1350', );
                      if (value == 1800) return _bottomTitle('1800',);
                      return const Text('');
                    },
                  ),
                ),
                
                // Trục X
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      // value ở đây là index (0, 1, 2...)
                      final int hour = _data[value.toInt()].hour;
                      return _bottomTitle('${hour.toString().padLeft(2, '0')}:00', );
                    },
                  ),
                ),
              ),
              
              // 3. Cài đặt lưới
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              
              // 4. Bỏ viền
              borderData: FlBorderData(show: false),
              
              // 5. Dữ liệu cột
              barGroups: _generateBarGroups(),

              // 6. Giới hạn Y
              maxY: 1800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 7. Chú thích (Legend)
        _buildLegend(),
      ],
    );
  }

  // Hàm tạo các cột dữ liệu
  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(_data.length, (index) {
      final item = _data[index];
      
      // Tính tổng (để làm phần nền)
      final total = item.nhap + item.xuat;

      return BarChartGroupData(
        x: index, // Vị trí (0, 1, 2...)
        barRods: [
          BarChartRodData(
            toY: total,
            width: 35,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            // Đây là phần xếp chồng (Stacked)
            rodStackItems: [
              // Lớp 1 (dưới): Cân Nhập (Xanh)
              BarChartRodStackItem(0, item.nhap, colorNhap),
              
              // Lớp 2 (trên): Cân Xuất (Đỏ)
              BarChartRodStackItem(item.nhap, total, colorXuat),
            ],
            // Màu nền cho phần còn lại của cột (lên đến maxY)
            color: Colors.grey[200], 
          ),
        ],
      );
    });
  }

  // Widget helper cho chú thích
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(colorNhap, 'Khối lượng cân nhập'),
        const SizedBox(width: 16),
        _legendItem(colorXuat, 'Khối lượng cân xuất'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  // Widget helper cho các tiêu đề (Trục X, Y)
  Widget _bottomTitle(String text) { // <-- 1. Thêm 'TitleMeta meta'
    return SideTitleWidget(
      axisSide: AxisSide.bottom, // <-- 3. XÓA DÒNG NÀY
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}