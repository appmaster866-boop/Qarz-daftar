import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/sales_service.dart';
import '../utils/format.dart';

/// Yangi savdo qo'shish uchun pastdan chiqadigan oyna.
/// Ham "Savdolar" ekranidan, ham Kalkulyatordan ishlatiladi.
class AddSaleSheet extends StatefulWidget {
  final double? initialAmount;
  final DateTime date;

  const AddSaleSheet({super.key, this.initialAmount, required this.date});

  static Future<bool?> show(
    BuildContext context, {
    double? initialAmount,
    DateTime? date,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // klaviatura chiqqanda oyna ko'tariladi
      showDragHandle: true,
      builder: (_) => AddSaleSheet(
        initialAmount: initialAmount,
        date: date ?? DateTime.now(),
      ),
    );
  }

  @override
  State<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<AddSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _service = SalesService();
  PaymentType _type = PaymentType.cash;
  bool _saved = false; // ikki marta bosishdan himoya

  @override
  void initState() {
    super.initState();
    final a = widget.initialAmount;
    if (a != null && a > 0) {
      _amountCtrl.text =
          a == a.truncateToDouble() ? a.toInt().toString() : a.toString();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String? text) =>
      double.tryParse((text ?? '').replaceAll(' ', '').replaceAll(',', '.'));

  void _save() {
    if (_saved) return; // allaqachon saqlangan bo'lsa, qayta saqlamaymiz
    if (!_formKey.currentState!.validate()) return;
    _saved = true;

    final d = widget.date;
    final now = DateTime.now();
    final sale = Sale(
      id: '',
      amount: _parseAmount(_amountCtrl.text)!,
      note: _noteCtrl.text.trim(),
      paymentType: _type,
      customerName:
          _type == PaymentType.debt ? _customerCtrl.text.trim() : null,
      // Tanlangan kun + hozirgi vaqt
      createdAt: DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second),
    );

    // Eslatma: internet bo'lmasa ham Firestore ma'lumotni qurilmada saqlab,
    // aloqa tiklanganda yuboradi. Shuning uchun natijani kutib o'tirmaymiz.
    _service.addSale(sale).catchError((e) => debugPrint('Saqlashda xato: $e'));

    Navigator.pop(context, true); // true = savdo saqlandi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Savdo qo'shildi: ${formatMoney(sale.amount)}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Klaviatura balandligi kadar pastdan joy qoldiramiz
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Yangi savdo",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Summa
              TextFormField(
                controller: _amountCtrl,
                autofocus: widget.initialAmount == null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Summa',
                  suffixText: "so'm",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = _parseAmount(v);
                  if (n == null || n <= 0) return "To'g'ri summa kiriting";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Izoh
              TextFormField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)',
                  hintText: "Masalan: non, sut, yog'",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // To'lov turi
              SegmentedButton<PaymentType>(
                segments: PaymentType.values
                    .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                    .toList(),
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),

              // Qarz bo'lsa mijoz ismi majburiy
              if (_type == PaymentType.debt) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Mijoz ismi',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Qarz uchun mijoz ismini kiriting'
                      : null,
                ),
              ],

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Saqlash'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
