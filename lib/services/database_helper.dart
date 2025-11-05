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

    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE VmlWorkS (
        maCode TEXT PRIMARY KEY,
        ovNO TEXT,
        package INTEGER,
        mUserID TEXT,
        qtys REAL,
        realQty REAL,
        mixTime TEXT,
        loai TEXT
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

  // Tự động thêm cột mới nếu DB cũ không có
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE VmlWorkS ADD COLUMN realQty REAL');
      await db.execute('ALTER TABLE VmlWorkS ADD COLUMN mixTime TEXT');
      await db.execute('ALTER TABLE VmlWorkS ADD COLUMN loai TEXT');
    }
  }

  /// Lấy thông tin chi tiết của 1 mã code
  Future<Map<String, dynamic>?> getCodeInfo(String maCode) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT S.maCode, S.ovNO, S.package, S.mUserID, S.qtys,
             S.realQty, S.mixTime, S.loai,
             W.tenPhoiKeo, W.soMay, W.memo, W.totalTargetQty,
             P.nguoiThaoTac, S.package as soLo
      FROM VmlWorkS AS S
      LEFT JOIN VmlWork AS W ON S.ovNO = W.ovNO
      LEFT JOIN VmlPersion AS P ON S.mUserID = P.mUserID
      WHERE S.maCode = ?
    ''', [maCode]);

    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getPendingSyncRecords() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        H.id, H.maCode, H.khoiLuongCan, H.thoiGianCan, H.loai,
        S.package as soLo, W.tenPhoiKeo, P.nguoiThaoTac
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
  }

  /// Kiểm tra xem mã đã cân nhập chưa (offline)
  Future<bool> isCodeAlreadyNhap(String maCode) async {
    final db = await database;
    final result = await db.query('VmlWorkS',
        where: 'maCode = ? AND loai = ?', whereArgs: [maCode, 'nhap']);
    return result.isNotEmpty;
  }
}
