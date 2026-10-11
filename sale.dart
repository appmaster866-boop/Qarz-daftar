import 'package:cloud_firestore/cloud_firestore.dart';

/// To'lov turi: naqd, karta yoki qarz
enum PaymentType { cash, card, debt }

extension PaymentTypeX on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.cash:
        return 'Naqd';
      case PaymentType.card:
        return 'Karta';
      case PaymentType.debt:
        return 'Qarz';
    }
  }
}

/// Bitta savdo yozuvi
class Sale {
  final String id;
  final double amount; // summa
  final String note; // izoh (nima sotildi)
  final PaymentType paymentType;
  final String? customerName; // faqat qarz bo'lsa
  final DateTime createdAt;

  const Sale({
    required this.id,
    required this.amount,
    required this.note,
    required this.paymentType,
    required this.createdAt,
    this.customerName,
  });

  /// Firestore-ga yozish uchun
  Map<String, dynamic> toMap() => {
        'amount': amount,
        'note': note,
        'paymentType': paymentType.name,
        'customerName': customerName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Firestore-dan o'qish uchun
  factory Sale.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Sale(
      id: doc.id,
      amount: (m['amount'] as num).toDouble(),
      note: (m['note'] as String?) ?? '',
      paymentType: PaymentType.values.firstWhere(
        (t) => t.name == m['paymentType'],
        orElse: () => PaymentType.cash,
      ),
      customerName: m['customerName'] as String?,
      createdAt: (m['createdAt'] as Timestamp).toDate(),
    );
  }
}
