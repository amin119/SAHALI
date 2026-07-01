import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QueuedReport {
  final int id;
  final Map<String, dynamic> payload;
  final int createdAt;

  const QueuedReport({
    required this.id,
    required this.payload,
    required this.createdAt,
  });
}

class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'sahali_queue.db'),
      onCreate: (db, _) => db.execute('''
        CREATE TABLE queued_reports (
          id       INTEGER PRIMARY KEY AUTOINCREMENT,
          payload  TEXT    NOT NULL,
          created_at INTEGER NOT NULL
        )
      '''),
      version: 1,
    );
  }

  Future<void> enqueue(Map<String, dynamic> payload) async {
    final db = await _database;
    await db.insert('queued_reports', {
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<QueuedReport>> getPending() async {
    final db = await _database;
    final rows = await db.query('queued_reports', orderBy: 'created_at ASC');
    return rows
        .map((r) => QueuedReport(
              id: r['id'] as int,
              payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
              createdAt: r['created_at'] as int,
            ))
        .toList();
  }

  Future<void> remove(int id) async {
    final db = await _database;
    await db.delete('queued_reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM queued_reports');
    return (result.first['c'] as int?) ?? 0;
  }
}
