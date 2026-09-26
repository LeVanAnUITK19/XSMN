import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/ticket_history_model.dart';

/// Singleton service quản lý SQLite
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'xsmn_v2.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ticket_history (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketNumber TEXT NOT NULL,
            station      TEXT NOT NULL,
            drawDate     TEXT NOT NULL,
            isWin        INTEGER NOT NULL DEFAULT 0,
            prizeName    TEXT,
            grossPrize   INTEGER NOT NULL DEFAULT 0,
            taxAmount    INTEGER NOT NULL DEFAULT 0,
            netPrize     INTEGER NOT NULL DEFAULT 0,
            checkedAt    TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Thêm 3 cột mới cho version 2
          await db.execute(
              'ALTER TABLE ticket_history ADD COLUMN grossPrize INTEGER NOT NULL DEFAULT 0');
          await db.execute(
              'ALTER TABLE ticket_history ADD COLUMN taxAmount INTEGER NOT NULL DEFAULT 0');
          await db.execute(
              'ALTER TABLE ticket_history ADD COLUMN netPrize INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  // ── TICKET HISTORY ────────────────────────────────────────────

  Future<int> insertTicketHistory(TicketHistory history) async {
    final db = await database;
    return db.insert('ticket_history', history.toMap());
  }

  Future<List<TicketHistory>> getAllTicketHistories() async {
    final db = await database;
    final maps = await db.query(
      'ticket_history',
      orderBy: 'checkedAt DESC',
    );
    return maps.map(TicketHistory.fromMap).toList();
  }

  Future<int> deleteTicketHistory(int id) async {
    final db = await database;
    return db.delete('ticket_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllTicketHistories() async {
    final db = await database;
    return db.delete('ticket_history');
  }

  /// Thống kê tổng hợp từ SQLite — KHÔNG gọi backend
  Future<TicketStats> getStats() async {
    final all = await getAllTicketHistories();
    final wins = all.where((h) => h.isWin).toList();

    // Thống kê theo đài
    final Map<String, _StationStat> byStation = {};
    for (final h in all) {
      byStation.putIfAbsent(h.station, () => _StationStat(h.station));
      byStation[h.station]!.total++;
      if (h.isWin) byStation[h.station]!.wins++;
    }

    return TicketStats(
      total: all.length,
      totalWins: wins.length,
      byStation: byStation.values
          .map((s) => StationStat(
                station: s.station,
                total: s.total,
                wins: s.wins,
              ))
          .toList()
        ..sort((a, b) => b.total.compareTo(a.total)),
    );
  }
}

class _StationStat {
  final String station;
  int total = 0;
  int wins = 0;
  _StationStat(this.station);
}

class TicketStats {
  final int total;
  final int totalWins;
  final List<StationStat> byStation;

  const TicketStats({
    required this.total,
    required this.totalWins,
    required this.byStation,
  });

  int get totalLosses => total - totalWins;
  double get winRate => total == 0 ? 0 : totalWins / total;
}

class StationStat {
  final String station;
  final int total;
  final int wins;
  const StationStat({
    required this.station,
    required this.total,
    required this.wins,
  });
  int get losses => total - wins;
}
