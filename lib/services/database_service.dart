import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';
import '../models/fuel_record.dart';
import '../models/break_record.dart';
import '../models/cargo_record.dart';
import '../models/expense_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('truck_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 運行記録テーブル
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_location TEXT,
        end_location TEXT,
        destination TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 給油記録テーブル
    await db.execute('''
      CREATE TABLE fuel_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER,
        timestamp TEXT NOT NULL,
        location TEXT,
        liters REAL NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');

    // 休憩記録テーブル
    await db.execute('''
      CREATE TABLE break_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        break_type TEXT NOT NULL,
        location TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');

    // 荷積・荷下ろし記録テーブル
    await db.execute('''
      CREATE TABLE cargo_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT,
        customer TEXT,
        photo_path TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');

    // 経費記録テーブル
    await db.execute('''
      CREATE TABLE expense_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER,
        timestamp TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        receipt_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');
  }

  // Trip CRUD operations
  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'created_at DESC');
    return maps.map((map) => Trip.fromMap(map)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  Future<Trip?> getCurrentTrip() async {
    final db = await database;
    final maps = await db.query(
      'trips',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // FuelRecord CRUD operations
  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.insert('fuel_records', record.toMap());
  }

  Future<List<FuelRecord>> getFuelRecordsByTrip(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'fuel_records',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => FuelRecord.fromMap(map)).toList();
  }

  Future<List<FuelRecord>> getAllFuelRecords() async {
    final db = await database;
    final maps = await db.query('fuel_records', orderBy: 'timestamp DESC');
    return maps.map((map) => FuelRecord.fromMap(map)).toList();
  }

  Future<int> updateFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.update(
      'fuel_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteFuelRecord(int id) async {
    final db = await database;
    return await db.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
  }

  // BreakRecord CRUD operations
  Future<int> insertBreakRecord(BreakRecord record) async {
    final db = await database;
    return await db.insert('break_records', record.toMap());
  }

  Future<List<BreakRecord>> getBreakRecordsByTrip(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'break_records',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => BreakRecord.fromMap(map)).toList();
  }

  Future<List<BreakRecord>> getAllBreakRecords() async {
    final db = await database;
    final maps = await db.query('break_records', orderBy: 'start_time DESC');
    return maps.map((map) => BreakRecord.fromMap(map)).toList();
  }

  Future<BreakRecord?> getActiveBreakRecord() async {
    final db = await database;
    final maps = await db.query(
      'break_records',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return BreakRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBreakRecord(BreakRecord record) async {
    final db = await database;
    return await db.update(
      'break_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteBreakRecord(int id) async {
    final db = await database;
    return await db.delete('break_records', where: 'id = ?', whereArgs: [id]);
  }

  // CargoRecord CRUD operations
  Future<int> insertCargoRecord(CargoRecord record) async {
    final db = await database;
    return await db.insert('cargo_records', record.toMap());
  }

  Future<List<CargoRecord>> getCargoRecordsByTrip(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'cargo_records',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => CargoRecord.fromMap(map)).toList();
  }

  Future<List<CargoRecord>> getAllCargoRecords() async {
    final db = await database;
    final maps = await db.query('cargo_records', orderBy: 'timestamp DESC');
    return maps.map((map) => CargoRecord.fromMap(map)).toList();
  }

  Future<int> updateCargoRecord(CargoRecord record) async {
    final db = await database;
    return await db.update(
      'cargo_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteCargoRecord(int id) async {
    final db = await database;
    return await db.delete('cargo_records', where: 'id = ?', whereArgs: [id]);
  }

  // ExpenseRecord CRUD operations
  Future<int> insertExpenseRecord(ExpenseRecord record) async {
    final db = await database;
    return await db.insert('expense_records', record.toMap());
  }

  Future<List<ExpenseRecord>> getExpenseRecordsByTrip(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'expense_records',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ExpenseRecord.fromMap(map)).toList();
  }

  Future<List<ExpenseRecord>> getAllExpenseRecords() async {
    final db = await database;
    final maps = await db.query('expense_records', orderBy: 'timestamp DESC');
    return maps.map((map) => ExpenseRecord.fromMap(map)).toList();
  }

  Future<int> updateExpenseRecord(ExpenseRecord record) async {
    final db = await database;
    return await db.update(
      'expense_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteExpenseRecord(int id) async {
    final db = await database;
    return await db.delete('expense_records', where: 'id = ?', whereArgs: [id]);
  }

  // Statistics and summary methods
  Future<Map<String, dynamic>> getTripSummary(int tripId) async {
    final db = await database;
    
    // 給油統計
    final fuelResult = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(liters) as total_liters, SUM(amount) as total_amount
      FROM fuel_records WHERE trip_id = ?
    ''', [tripId]);
    
    // 経費統計
    final expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total_expense
      FROM expense_records WHERE trip_id = ?
    ''', [tripId]);
    
    // 休憩統計
    final breakResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM break_records WHERE trip_id = ? AND end_time IS NOT NULL
    ''', [tripId]);
    
    return {
      'fuel_count': fuelResult.first['count'] ?? 0,
      'total_liters': fuelResult.first['total_liters'] ?? 0.0,
      'total_fuel_cost': fuelResult.first['total_amount'] ?? 0.0,
      'total_expense': expenseResult.first['total_expense'] ?? 0.0,
      'break_count': breakResult.first['count'] ?? 0,
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

