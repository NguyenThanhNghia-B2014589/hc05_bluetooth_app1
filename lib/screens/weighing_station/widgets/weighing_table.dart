import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../controllers/weighing_station_controller.dart';

class WeighingTable extends StatelessWidget {
  final List<WeighingRecord> records;

  final WeighingType weighingType;

  const WeighingTable({
    super.key, 
    required this.records,
    required this.weighingType,
  });

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
                  rowColor = index.isEven ? Colors.white : const Color.fromARGB(255, 231, 231, 231); // Màu sọc vằn
                }
                return Container(
                  color: rowColor,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        dataCell(record.tenPhoiKeo, 3),
                        dataCell(record.soLo, 2),
                        dataCell(record.soMay, 2),
                        dataCell(record.nguoiThaoTac, 3),
                        dataCell(record.khoiLuongMe.toStringAsFixed(3), 3),
                        dataCell(
                          // Nếu chưa cân (null) thì hiển thị '---'
                          record.khoiLuongDaCan?.toStringAsFixed(3) ?? '---', 3),
                        Builder(
                          builder: (context) {
                            String thoiGianText;
                            if (record.thoiGianCan == null) {
                              thoiGianText = '---'; // chưa có thời gian cân '---'
                            } else {
                              final dt = record.thoiGianCan!;
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
        ],
      ),
    );
  }
}