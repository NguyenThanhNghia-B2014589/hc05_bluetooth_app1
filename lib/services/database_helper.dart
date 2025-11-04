import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "weighing_app.db");
    
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Hàm này chạy LẦN ĐẦU TIÊN khi app cài đặt
  Future _onCreate(Database db, int version) async {
    // 1. Tạo bảng để cache thông tin (giúp tra cứu offline)
    // (Chúng ta chỉ cache những gì cần thiết cho việc tra cứu)
    await db.execute('''
      CREATE TABLE VmlWorkS (
        maCode TEXT PRIMARY KEY,
        ovNO TEXT,
        package INTEGER,
        mUserID TEXT,
        qtys REAL
        realQty REAL,
        mixTime TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE VmlWork (
        ovNO TEXT PRIMARY KEY,
        tenPhoiKeo TEXT,
        soMay TEXT,
        memo TEXT,
        totalTargetQty REAL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE VmlPersion (
        mUserID TEXT PRIMARY KEY,
        nguoiThaoTac TEXT
      )
    ''');

    // 2. TẠO BẢNG HÀNG ĐỢI (QUAN TRỌNG NHẤT)
    // Bảng này lưu các lần cân chưa được gửi lên server
    await db.execute('''
      CREATE TABLE HistoryQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        maCode TEXT NOT NULL,
        khoiLuongCan REAL,
        thoiGianCan TEXT,
        loai TEXT
      )
    ''');
  }

  /// Lấy tất cả các bản ghi đang chờ đồng bộ (trong HistoryQueue)
  /// và JOIN với cache để lấy thông tin chi tiết.
  Future<List<Map<String, dynamic>>> getPendingSyncRecords() async {
    final db = await database;
    
    // Query này sẽ JOIN Queue với 3 bảng cache
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        H.id,
        H.maCode,
        H.khoiLuongCan,
        H.thoiGianCan,
        H.loai,
        S.package as soLo,
        W.tenPhoiKeo,
        P.nguoiThaoTac
      FROM 
        HistoryQueue AS H
      LEFT JOIN 
        VmlWorkS AS S ON H.maCode = S.maCode
      LEFT JOIN 
        VmlWork AS W ON S.ovNO = W.ovNO
      LEFT JOIN 
        VmlPersion AS P ON S.mUserID = P.mUserID
      ORDER BY 
        H.id ASC
    ''');
    
    return result;
  }
}