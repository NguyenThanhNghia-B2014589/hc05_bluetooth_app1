import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../controllers/weighing_station_controller.dart'; // Giữ import này

class WeighingTable extends StatelessWidget {
  final List<WeighingRecord> records;
  final WeighingType weighingType;
  final String? activeOVNO;
  final String? activeMemo;

  const WeighingTable({
    super.key,
    required this.records,
    required this.weighingType,
    this.activeOVNO,
    this.activeMemo,
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20);
    const cellStyle = TextStyle(fontSize: 20);
    const summaryStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87);

    Widget verticalDivider() => Container(width: 1, color: Colors.white.withValues(alpha: 1));
    Widget headerCell(String title, int flex) 
    => Expanded(
      flex: flex, 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), 
        child: Center(
          child: Text(title, style: headerStyle, textAlign: TextAlign.center))));

    Widget dataCell(String text, int flex) => Expanded(
        flex: flex,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Center(
                child: Text(text, style: cellStyle, textAlign: TextAlign.center))));

    // Header động cho cột Khối Lượng Mẻ/Tồn
    final String khoiLuongMeHeader =
        (weighingType == WeighingType.nhap)
            ? 'Khối Lượng Mẻ (kg)' 
            //'Khối Lượng Tồn (kg)' //chưa dùng
            : 'Khối Lượng Mẻ (kg)';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          // --- HEADER ROW (Đã cập nhật) ---
          Container(
            color: const Color(0xFF40B9FF),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  headerCell('Tên Phôi Keo', 3), verticalDivider(),
                  headerCell('Số Lô', 2), verticalDivider(),
                  headerCell('Số Máy', 2), verticalDivider(),
                  headerCell('Người Thao Tác', 3), verticalDivider(),
                  headerCell(khoiLuongMeHeader, 3), verticalDivider(),
                  headerCell('Khối Lượng Đã Cân (kg)', 3), verticalDivider(),
                  headerCell('Thời Gian Cân', 3),
                ],
              ),
            ),
          ),
          // --- KẾT THÚC HEADER ---

          if (records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Vui lòng scan mã để hiển thị thông tin', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
              ),
            )
          else
            // --- DATA ROWS (Đã cập nhật) ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                // Chọn màu dựa trên trạng thái (isSuccess)
                Color rowColor;
                if (record.isSuccess == true) {
                  rowColor = const Color.fromARGB(255, 182, 240, 188); // Màu xanh lá nếu thành công
                } else {
                  rowColor = index.isEven ? Colors.white : const Color.fromARGB(255, 231, 231, 231); // Màu sọc vằn
                }

                return Container(
                  color: rowColor,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        dataCell(record.tenPhoiKeo ?? 'N/A', 3), // FormulaF
                        dataCell(record.soLo.toString(), 2), // package
                        dataCell(record.soMay, 2), // soMay
                        dataCell(record.nguoiThaoTac ?? 'N/A', 3), // UerName
                        dataCell(record.qty.toStringAsFixed(3), 3), // Mẻ/Tồn
                        dataCell(record.realQty?.toStringAsFixed(3) ?? '---', 3), // Đã Cân
                        Builder(
                          builder: (context) {
                            String thoiGianText;
                            if (record.mixTime == null) {
                              thoiGianText = '---'; // chưa có thời gian cân '---'
                            } else {
                              final dt = record.mixTime!;
                              // Định dạng: dd/MM/yyyy HH:mm
                              final d = dt.day.toString().padLeft(2, '0');
                              final m = dt.month.toString().padLeft(2, '0');
                              final y = dt.year;
                              final h = dt.hour.toString().padLeft(2, '0');
                              final min = dt.minute.toString().padLeft(2, '0');
                              thoiGianText = '$d/$m/$y  $h:$min';
                            }
                            return dataCell(thoiGianText, 3);
                          }
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (activeOVNO != null) // Only show if there's an active OVNO
          Container(
            color: const Color.fromARGB(255, 218, 221, 40), // Light green background
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Text('OVNO : $activeOVNO', style: summaryStyle),
                const Spacer(flex: 1),
                const Text('Số lô tổng: ---', style: summaryStyle),
                const Spacer(flex: 1),
                const Text('Nhập: --- kg', style: summaryStyle),
                const Spacer(flex: 1),
                const Text('Xuất: --- kg', style: summaryStyle),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Memo: ${activeMemo ?? ''}', // Display Memo
                    style: summaryStyle,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}