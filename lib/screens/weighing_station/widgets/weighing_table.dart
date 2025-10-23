import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';

class WeighingTable extends StatelessWidget {
  final List<WeighingRecord> records;

  const WeighingTable({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20);
    const cellStyle = TextStyle(fontSize: 20);

    Widget verticalDivider() => Container(width: 1, color: Colors.white.withValues(alpha: 1));
    Widget headerCell(String title, int flex) 
    => Expanded(
      flex: flex, 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), 
        child: Center(
          child: Text(title, style: headerStyle, textAlign: TextAlign.center))));

    Widget dataCell(String text, int flex) 
    => Expanded(
      flex: flex, 
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0), 
      child: Center(
        child: Text(text, style: cellStyle, textAlign: TextAlign.center))));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF40B9FF),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  headerCell('Tên Phôi Keo', 2), verticalDivider(),
                  headerCell('Số Lô', 2), verticalDivider(),
                  headerCell('Số Máy', 2), verticalDivider(),
                  headerCell('Khối Lượng Mẻ (kg)', 2), verticalDivider(),
                  headerCell('Người Thao Tác', 2), verticalDivider(),
                  headerCell('Thời Gian Cân', 2),
                ],
              ),
            ),
          ),
          if (records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Vui lòng quét mã để hiển thị thông tin', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                // --- LOGIC CHỌN MÀU MỚI ---
                Color rowColor;
                if (record.isSuccess == true) {
                  rowColor = const Color.fromARGB(255, 202, 240, 206); // Màu xanh lá nếu thành công
                } else {
                  rowColor = index.isEven ? Colors.white : Colors.grey.shade50; // Màu sọc vằn
                }
                return Container(
                  color: rowColor,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        dataCell(record.tenPhoiKeo, 2),
                        dataCell(record.soLo, 2),
                        dataCell(record.soMay, 2),
                        dataCell(record.khoiLuongMe.toStringAsFixed(3), 2),
                        dataCell(record.nguoiThaoTac, 2),
                        dataCell('${record.thoiGianCan.hour.toString().padLeft(2, '0')}:${record.thoiGianCan.minute.toString().padLeft(2, '0')}', 2),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}