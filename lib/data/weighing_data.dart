// Class model cho bản ghi cân
class WeighingRecord {
  final String tenPhoiKeo;
  final String soLo;
  final String soMay;
  final double khoiLuongMe;
  final String nguoiThaoTac;
  DateTime? thoiGianCan;
  final double? khoiLuongSauCan;

  bool? isSuccess;

  WeighingRecord({
    required this.tenPhoiKeo,
    required this.soLo,
    required this.soMay,
    required this.khoiLuongMe,
    required this.nguoiThaoTac,
    this.thoiGianCan,
    this.khoiLuongSauCan,
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

final Map<String, Map<String, dynamic>> mockLastWeighingData = {
  '123': {
    'tenPhoiKeo': 'Phôi keo A',
    'soLo': 'Lô 1',
    'soMay': 'Máy 1',
    'nguoiThaoTac': 'Nguyen Van A',
    'thoiGianCan': '10:26 16/08/2025',
    'khoiLuongMe': 20.000,
    'khoiLuongSauCan': 19.900,
  },
  '456': {
    'tenPhoiKeo': 'Phôi keo B',
    'soLo': 'Lô 2',
    'soMay': 'Máy 3',
    'nguoiThaoTac': 'Nguyen Van B',
    'thoiGianCan': '09:15 16/08/2025',
    'khoiLuongMe': 73.262,
    'khoiLuongSauCan': 73.100,
  },
  '789': {
    'tenPhoiKeo': 'Phôi keo C-VIP',
    'soLo': 'Lô 7',
    'soMay': 'Máy 1',
    'nguoiThaoTac': 'Nguyen Van C',
    'thoiGianCan': '11:00 16/08/2025',
    'khoiLuongMe': 44.489,
    'khoiLuongSauCan': 44.300,
  },
};