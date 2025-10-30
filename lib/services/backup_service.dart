import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction.dart' as app;
import '../utils/helpers.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  Future<void> ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (error) {
      debugPrint('Firebase init failed: $error');
    }
  }

  Future<File> exportTransactionsToCsv(
    List<app.Transaction> transactions,
  ) async {
    final rows = <List<dynamic>>[
      ['Title', 'Amount', 'Category', 'Type', 'Date'],
      for (final tx in transactions)
        [
          tx.title,
          tx.amount.toStringAsFixed(2),
          tx.category,
          tx.type.name,
          tx.date.toIso8601String(),
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final file = await _createFile('transactions.csv');
    await file.writeAsString(csv);
    return file;
  }

  Future<File> exportTransactionsToPdf(
    List<app.Transaction> transactions,
  ) async {
    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(base: pw.Font.helvetica());

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          pw.Text(
            'ExpenseFlow Monthly Summary',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Title', 'Amount', 'Category', 'Type', 'Date'],
            data: [
              for (final tx in transactions)
                [
                  tx.title,
                  formatCurrency(tx.amount),
                  tx.category,
                  tx.type.name,
                  formatDate(tx.date),
                ],
            ],
          ),
        ],
      ),
    );

    final file = await _createFile('transactions.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> syncTransactionsToCloud(
    String userId,
    List<app.Transaction> transactions,
  ) async {
    await ensureFirebaseInitialized();
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final collection = firestore
          .collection('expenseflow_users')
          .doc(userId)
          .collection('transactions');

      final snapshots = await collection.get();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      for (final tx in transactions) {
        final ref = collection.doc();
        batch.set(ref, {
          'title': tx.title,
          'amount': tx.amount,
          'category': tx.category,
          'type': tx.type.name,
          'date': tx.date.toIso8601String(),
        });
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Cloud sync failed: $error');
      rethrow;
    }
  }

  Future<File> _createFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, filename);
    return File(path);
  }
}
