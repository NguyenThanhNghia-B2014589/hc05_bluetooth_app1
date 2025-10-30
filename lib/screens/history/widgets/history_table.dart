import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/weighing_data.dart'; // Import model

class SummaryData {
  final String ovNO;
  final String? memo; // Lấy từ mockWorkData

  SummaryData({required this.ovNO, this.memo});
}

class HistoryTable extends StatelessWidget {
  final List<WeighingRecord> records;
  const HistoryTable({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
  // --- Định nghĩa Style (Giữ nguyên) ---
  const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13);
  const cellStyle = TextStyle(fontSize: 14);
  const summaryStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87);

  // --- Widget Helper (Giữ nguyên headerCell, dataCell) ---
  Widget headerCell(String title, int flex) => Expanded(
        flex: flex,
        child: Container(
          color: const Color(0xFF40B9FF), // Màu xanh nhạt header
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
              child: Text(title, style: headerStyle, textAlign: TextAlign.center)),
        ));
  Widget dataCell(String text, int flex, {TextAlign align = TextAlign.center}) => Expanded(
      flex: flex,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Text(text, style: cellStyle, textAlign: TextAlign.center)));

    Widget verticalDivider() => Container(width: 1, color: Colors.white.withValues(alpha: 1));
    // Định dạng ngày giờ
    String formatDateTime(DateTime? dt) {
      if (dt == null) return '---';
      return DateFormat('dd/MM/yyyy HH:mm').format(dt); // Giữ format đầy đủ
    }
  // --- XỬ LÝ DỮ LIỆU ĐỂ HIỂN THỊ (NHÓM VÀ TÍNH TOÁN) ---

  // 1. Nhóm các record theo ovNO
  Map<String, List<WeighingRecord>> groupedData = {};
  for (var record in records) {
    // Thêm record vào list của ovNO tương ứng
    (groupedData[record.ovNO] ??= []).add(record);
  }

  // 2. Tạo danh sách phẳng để hiển thị (chứa cả Record và Summary)
  List<dynamic> displayList = [];
  groupedData.forEach((ovNO, recordList) {
    // Thêm tất cả các record của nhóm này
    displayList.addAll(recordList);

    // Tìm Memo từ mockWorkData
    final workItem = mockWorkData[ovNO];
    final memo = workItem?['Memo'] as String?;

    // Thêm hàng tóm tắt cho nhóm này
    displayList.add(SummaryData(ovNO: ovNO, memo: memo));
  });

  // --- GIAO DIỆN BẢNG (CONTAINER VÀ HEADER GIỮ NGUYÊN) ---
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: Column(
        children: [
          // Header Row (Giữ nguyên)
          IntrinsicHeight(
            child: Row(
              children: [
                headerCell('Mã Code', 3), verticalDivider(),
                headerCell('Tên Phôi Keo', 4), verticalDivider(),
                headerCell('Số Lô', 3), verticalDivider(),
                headerCell('Số Máy', 3), verticalDivider(),
                headerCell('Người Thao Tác', 4), verticalDivider(),
                headerCell('Thời Gian Cân', 4), verticalDivider(),
                headerCell('KL Mẻ/Tồn(kg)', 3), verticalDivider(),
                headerCell('KL Đã Cân(kg)', 3), verticalDivider(),
                headerCell('Loại Cân', 3), 
              ],
            ),
          ),

          // --- SỬA LẠI PHẦN BODY (DÙNG displayList) ---
          Expanded(
            child: Container(
              color: Colors.white,
              child: displayList.isEmpty
                ? Center(child: Text('Không có dữ liệu lịch sử.', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
                    itemCount: displayList.length, // Dùng list mới
                    itemBuilder: (context, index) {
                      final item = displayList[index];

                      // KIỂM TRA LOẠI ITEM ĐỂ RENDER ĐÚNG HÀNG
                      if (item is WeighingRecord) {
                        // RENDER HÀNG DỮ LIỆU (DATA ROW)
                        final record = item;
                        // Xác định màu nền xen kẽ (chỉ cho data row)
                        // Tìm index thực sự của record này trong list gốc để biết chẵn/lẻ
                        final originalIndex = records.indexWhere((r) => r.maCode == record.maCode && r.mixTime == record.mixTime); // Cần cách xác định duy nhất
                        final bool isEven = originalIndex % 2 == 0;

                        return Container(
                          color: isEven ? Colors.white :const Color.fromARGB(255, 231, 231, 231),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                dataCell(record.maCode, 3),
                                dataCell(record.tenPhoiKeo ?? 'N/A', 4, align: TextAlign.left), // Căn trái
                                dataCell(record.soLo.toString(), 3),
                                dataCell(record.soMay, 3),
                                dataCell(record.nguoiThaoTac ?? 'N/A', 4, align: TextAlign.left), // Căn trái
                                dataCell(formatDateTime(record.mixTime), 4),
                                dataCell(record.qty.toStringAsFixed(3), 3, align: TextAlign.right), // Căn phải
                                dataCell(record.realQty?.toStringAsFixed(3) ?? '---', 3, align: TextAlign.right), // Căn phải
                                dataCell(record.loai ?? 'N/A', 3),
                              ],
                            ),
                          ),
                        );
                      } else if (item is SummaryData) {
                        // RENDER HÀNG TÓM TẮT (SUMMARY ROW)
                        final summary = item;
                        return Container(
                          color: Colors.green.shade100, // Màu xanh lá nhạt
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              Text('OVNO : ${summary.ovNO}', style: summaryStyle),
                              const Spacer(flex: 1),
                              const Text('Số lô tổng: ---', style: summaryStyle),
                              const Spacer(flex: 1),
                              const Text('Nhập: --- kg', style: summaryStyle),
                              const Spacer(flex: 1),
                              const Text('Xuất: --- kg', style: summaryStyle),
                              const Spacer(flex: 1),
                              Expanded( // Cho Memo chiếm phần còn lại
                                flex: 3, // Tăng flex cho Memo
                                child: Text(
                                  'Memo: ${summary.memo ?? ''}',
                                  style: summaryStyle,
                                  textAlign: TextAlign.right, // Căn phải
                                  overflow: TextOverflow.ellipsis, // Tránh tràn
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Trường hợp khác (không xảy ra)
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}