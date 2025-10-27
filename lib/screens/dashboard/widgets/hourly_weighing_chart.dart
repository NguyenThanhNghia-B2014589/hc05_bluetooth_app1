import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Dữ liệu mẫu
class ChartData {
  final int hour;
  final double nhap;
  final double xuat;
  const ChartData(this.hour, this.nhap, this.xuat);
}

class HourlyWeighingChart extends StatelessWidget {
  const HourlyWeighingChart({super.key, required this.data});
  // Màu sắc
  static const Color colorNhap = Color(0xFF81C784); // Xanh lá
  static const Color colorXuat = Color(0xFFE57373); // Đỏ
  final List<ChartData> data;
  
  @override
  Widget build(BuildContext context) {
    // --- 5. TÍNH TOÁN maxY ĐỘNG ---
    double maxY = 1800; // Mặc định
    if (data.isNotEmpty) {
      // Tìm giá trị tổng lớn nhất
      final maxVal = data.map((d) => d.nhap + d.xuat).reduce((a, b) => a > b ? a : b);
      // Làm tròn lên 450 gần nhất (giống trục Y)
      maxY = (maxVal / 450).ceil() * 450;
      if (maxY == 0) maxY = 1800; // Tránh trường hợp 0
    }
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
                      if (value == 0) return _bottomTitle('0', meta);
                      if (value == 100) return _bottomTitle('100', meta);
                      if (value == 200) return _bottomTitle('200', meta);
                      if (value == 300) return _bottomTitle('300', meta);
                      if (value == 400) return _bottomTitle('400', meta);
                      if (value == 900) return _bottomTitle('900', meta);
                      if (value == 1350) return _bottomTitle('1350', meta);
                      if (value == 1800) return _bottomTitle('1800',meta);
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
                      if (value.toInt() >= 0 && value.toInt() < data.length) {
                        final int hour = data[value.toInt()].hour;
                        return _bottomTitle('${hour.toString().padLeft(2, '0')}:00', meta);
                      }
                      return const Text('');
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
              // 5. Cài đặt tương tác
              barTouchData: BarTouchData(
                // Kích hoạt tooltip
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  // Hàm tùy chỉnh nội dung tooltip
                  getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    String title;
                    double value;
                    
                    // Lấy dữ liệu từ data list
                    final chartData = data[groupIndex];

                    // Kiểm tra vị trí click dựa trên rodIndex
                    if (rodIndex == 0) {
                      // Click vào phần Nhập (xanh lá)
                      title = 'Khối lượng nhập:';
                      value = chartData.nhap;
                    } else {
                      // Click vào phần Xuất (đỏ)
                      title = 'Khối lượng xuất:';
                      value = chartData.xuat;
                    }
                    
                    // Ẩn tooltip nếu bấm vào phần có giá trị = 0
                    if (value == 0) {
                      return null;
                    }

                    return BarTooltipItem(
                      '$title\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: value.toStringAsFixed(4), 
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 5. Dữ liệu cột
              barGroups: _generateBarGroups(),

              // 6. Giới hạn Y
              maxY: maxY,
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
    return List.generate(data.length, (index) {
      final item = data[index];
      
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
  Widget _bottomTitle(String text, TitleMeta meta) {
    return SideTitleWidget(
      meta : meta,
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}