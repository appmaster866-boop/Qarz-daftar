import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';

/// Firebase (Firestore) bilan ishlovchi servis.
/// Har bir foydalanuvchining savdolari faqat o'ziga tegishli:
///   users/{uid}/sales/{savdoId}
class SalesService {
  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales');
  }

  /// Tanlangan kunning savdolarini real vaqtda kuzatish (Stream)
  Stream<List<Sale>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);

    return _col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Sale.fromDoc).toList());
  }

  /// Yangi savdo qo'shish
  Future<void> addSale(Sale sale) => _col.add(sale.toMap());

  /// Savdoni o'chirish
  Future<void> deleteSale(String id) => _col.doc(id).delete();
}
