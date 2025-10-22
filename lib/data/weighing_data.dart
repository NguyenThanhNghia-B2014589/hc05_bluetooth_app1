// Class model cho bản ghi cân
class WeighingRecord {
  final String tenPhoiKeo;
  final String soLo;
  final String soMay;
  final double khoiLuongMe;
  final String nguoiThaoTac;
  final DateTime thoiGianCan;

  WeighingRecord({
    required this.tenPhoiKeo,
    required this.soLo,
    required this.soMay,
    required this.khoiLuongMe,
    required this.nguoiThaoTac,
    required this.thoiGianCan,
  });
}

  // --- THÊM DỮ LIỆU MẪU ---
  final Map<String, Map<String, dynamic>> mockWeighingData = {
  '123': {
    'tenPhoiKeo': 'Phôi keo A',
    'soLo': 'Lô 1',
    'soMay': 'Máy 1',
    'nguoiThaoTac': 'Nguyen Van A',
    'khoiLuongMe': 20.000,
  },
  '456': {
    'tenPhoiKeo': 'Phôi keo B',
    'soLo': 'Lô 2',
    'soMay': 'Máy 3',
    'nguoiThaoTac': 'Nguyen Van B',
    'khoiLuongMe': 73.262,
  },
  '789': {
    'tenPhoiKeo': 'Phôi keo C-VIP',
    'soLo': 'Lô 7',
    'soMay': 'Máy 1',
    'nguoiThaoTac': 'Nguyen Van C',
    'khoiLuongMe': 44.489,
  },
};