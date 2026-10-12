import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../engine/models.dart';

/// Saves blocks as JSON rows (replaces the hidden RAW_<block> sheets).
class BlockStore {
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'quantities.db');
    final db = await openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute(
          'CREATE TABLE blocks(name TEXT PRIMARY KEY, json TEXT NOT NULL, updated INTEGER NOT NULL)');
    });
    _db = db;
    return db;
  }

  Future<List<Block>> all() async {
    final db = await _database;
    final rows = await db.query('blocks', orderBy: 'updated DESC');
    return rows
        .map((r) => Block.fromJson(Map<String, dynamic>.from(jsonDecode(r['json'] as String) as Map)))
        .toList();
  }

  Future<void> save(Block b) async {
    final db = await _database;
    await db.insert(
      'blocks',
      {
        'name': b.name,
        'json': jsonEncode(b.toJson()),
        'updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String name) async {
    final db = await _database;
    await db.delete('blocks', where: 'name = ?', whereArgs: [name]);
  }
}
