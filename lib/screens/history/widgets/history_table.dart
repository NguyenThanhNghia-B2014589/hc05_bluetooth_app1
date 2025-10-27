import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần để format ngày
import '../../../data/weighing_data.dart'; // Import model

class HistoryTable extends StatelessWidget {
  final List<WeighingRecord> records;
  const HistoryTable({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16);
    const cellStyle = TextStyle(fontSize: 16);

    Widget headerCell(String title, int flex) => Expanded(
        flex: flex,
        child: Container(
          color: const Color(0xFF40B9FF), // Màu xanh nhạt header
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
              child: Text(title, style: headerStyle, textAlign: TextAlign.center)),
        ));

    Widget dataCell(String text, int flex) => Expanded(
        flex: flex,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Center(
                child: Text(text, style: cellStyle, textAlign: TextAlign.center))));

    Widget verticalDivider() => Container(width: 1, color: Colors.white.withValues(alpha: 1));
    // Định dạng ngày giờ
    String formatDateTime(DateTime? dt) {
      if (dt == null) return '---';
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: Column(
        children: [
          // 1. Header Row
          IntrinsicHeight(
            child: Row(
              children: [
                headerCell('Mã Code', 2), verticalDivider(),
                headerCell('Tên Phôi Keo', 3), verticalDivider(),
                headerCell('Số Lô', 2), verticalDivider(),
                headerCell('Số Máy', 2), verticalDivider(),
                headerCell('Người Thao Tác', 3), verticalDivider(),
                headerCell('Thời Gian Cân', 3), verticalDivider(),
                headerCell('Khối Lượng Mẻ (kg)', 3), verticalDivider(),
                headerCell('Khối Lượng Cân (kg)', 3), verticalDivider(),
                headerCell('Loại Cân', 2),
              ],
            ),
          ),
          
          // 2. Data Rows
          Expanded(
            child: Container(
              color: Colors.white, // Nền trắng cho các dòng dữ liệu
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Container(
                    color: index.isEven ? Colors.white :const Color.fromARGB(255, 231, 231, 231),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          dataCell(record.maCode, 2),
                          dataCell(record.tenPhoiKeo, 3),
                          dataCell(record.soLo, 2),
                          dataCell(record.soMay, 2),
                          dataCell(record.nguoiThaoTac, 3),
                          dataCell(formatDateTime(record.thoiGianCan), 3),
                          dataCell(record.khoiLuongMe.toStringAsFixed(3), 3),
                          dataCell(record.khoiLuongSauCan?.toStringAsFixed(3) ?? '---', 3),
                          dataCell(record.loai ?? '---', 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}