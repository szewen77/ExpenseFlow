import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget.dart';
import '../models/goal.dart';
import '../models/profile.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();
  static const _dbVersion = 2;

  sqflite.Database? _database;
  Future<void>? _recurringWarmup;

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<void> initDatabase() async {
    await database;
    _recurringWarmup ??= processRecurringTransactions();
    unawaited(_recurringWarmup!.catchError((_) {}));
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  Future<sqflite.Database> _openDatabase() async {
    if (kIsWeb) {
      // For web, use sqflite_common_ffi_web
      final databaseFactory = databaseFactoryFfiWeb;
      final dbPath = 'expenseflow.db';
      
      return await databaseFactory.openDatabase(
        dbPath,
        options: sqflite.OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: (db, _) async => _createSchema(db),
          onUpgrade: (db, oldVersion, _) async =>
              _upgradeSchema(db, oldVersion, _dbVersion),
        ),
      );
    } else {
      // For mobile/desktop platforms
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'expenseflow.db');

      try {
        return await sqflite.openDatabase(
          dbPath,
          version: _dbVersion,
          onCreate: (db, _) async => _createSchema(db),
          onUpgrade: (db, oldVersion, _) async =>
              _upgradeSchema(db, oldVersion, _dbVersion),
        );
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ Database open failed: $e');
        await sqflite.deleteDatabase(dbPath);
        return sqflite.openDatabase(
          dbPath,
          version: _dbVersion,
          onCreate: (db, _) async => _createSchema(db),
          onUpgrade: (db, oldVersion, _) async =>
              _upgradeSchema(db, oldVersion, _dbVersion),
        );
      }
    }
  }

  Future<void> _createSchema(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        avatarEmoji TEXT NOT NULL
      )
    ''');

    await db.insert(
      'profiles',
      UserProfile.defaultProfile.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        limitAmount REAL NOT NULL,
        period TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        interval TEXT NOT NULL,
        nextOccurrence INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeSchema(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createSchema(db);
    }

    if (oldVersion < newVersion) {
      // Future migrations can be added here.
    }
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction id cannot be null for update.');
    }
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? limit,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startOfDay(startDate).millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endOfDay(endDate).millisecondsSinceEpoch);
    }

    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    final result = await db.query(
      'transactions',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );

    return result.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getTransactionsForMonth(DateTime month) async {
    final start = startOfMonth(month);
    final end = endOfMonth(month);
    return getTransactions(startDate: start, endDate: end);
  }

  Future<Map<String, double>> categoryTotalsForMonth(DateTime month) async {
    final db = await database;
    final start = startOfMonth(month).millisecondsSinceEpoch;
    final end = endOfMonth(month).millisecondsSinceEpoch;

    final result = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE date BETWEEN ? AND ? AND type = ?
      GROUP BY category
    ''',
      [start, end, TransactionType.expense.name],
    );

    final totals = <String, double>{};
    for (final row in result) {
      totals[row['category'] as String] =
          (row['total'] as num?)?.toDouble() ?? 0;
    }
    return totals;
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    return getTransactions(limit: limit);
  }

  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final result = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [UserProfile.defaultProfile.id],
      limit: 1,
    );
    if (result.isEmpty) {
      return UserProfile.defaultProfile;
    }
    return UserProfile.fromMap(result.first);
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final result = await db.query('budgets', orderBy: 'category ASC');
    return result.map(Budget.fromMap).toList();
  }

  Future<void> upsertBudget(Budget budget) async {
    final db = await database;
    if (budget.id == null) {
      await db.insert('budgets', budget.toMap());
    } else {
      await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    }
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<Goal?> getGoal() async {
    final db = await database;
    final result = await db.query('goals', orderBy: 'endDate ASC', limit: 1);
    if (result.isEmpty) return null;
    return Goal.fromMap(result.first);
  }

  Future<void> upsertGoal(Goal goal) async {
    final db = await database;
    final existing = await db.query('goals', limit: 1);
    if (existing.isEmpty) {
      await db.insert('goals', goal.copyWith(id: null).toMap());
    } else {
      final currentId = existing.first['id'] as int;
      await db.update(
        'goals',
        goal.copyWith(id: currentId).toMap(),
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  Future<void> deleteGoal() async {
    final db = await database;
    await db.delete('goals');
  }

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    final result = await db.query(
      'recurring_transactions',
      orderBy: 'nextOccurrence ASC',
    );
    return result.map(RecurringTransaction.fromMap).toList();
  }

  Future<void> upsertRecurringTransaction(
    RecurringTransaction recurrence,
  ) async {
    final db = await database;
    if (recurrence.id == null) {
      await db.insert('recurring_transactions', recurrence.toMap());
    } else {
      await db.update(
        'recurring_transactions',
        recurrence.toMap(),
        where: 'id = ?',
        whereArgs: [recurrence.id],
      );
    }
    _recurringWarmup = processRecurringTransactions();
    unawaited(_recurringWarmup!.catchError((_) {}));
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    final recurrences = await getRecurringTransactions();

    for (final recurrence in recurrences) {
      var nextDate = recurrence.nextOccurrence;
      var updated = recurrence;

      while (!nextDate.isAfter(now)) {
        final transaction = Transaction(
          title: recurrence.title,
          amount: recurrence.amount,
          category: recurrence.category,
          date: nextDate,
          type: recurrence.type,
        );
        await insertTransaction(transaction);

        nextDate = _advanceDate(nextDate, recurrence.interval);
        updated = updated.copyWith(nextOccurrence: nextDate);
      }

      if (updated.nextOccurrence != recurrence.nextOccurrence) {
        await upsertRecurringTransaction(updated);
      }
    }
  }

  DateTime _advanceDate(DateTime date, RecurrenceInterval interval) {
    switch (interval) {
      case RecurrenceInterval.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceInterval.monthly:
        return addMonths(date, 1);
      case RecurrenceInterval.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}
