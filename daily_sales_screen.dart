import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/sales_service.dart';
import '../utils/format.dart';
import '../widgets/add_sale_sheet.dart';

/// Kunlik savdolar ro'yxati: sana tanlash, jami hisob va savdolar.
class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  final _service = SalesService();
  late DateTime _day;
  late Stream<List<Sale>> _stream;

  @override
  void initState() {
    super.initState();
    _day = DateTime.now();
    _stream = _service.watchDay(_day);
  }

  bool get _isToday => isSameDay(_day, DateTime.now());

  void _changeDay(DateTime newDay) {
    setState(() {
      _day = newDay;
      _stream = _service.watchDay(_day); // yangi kun uchun yangi oqim
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) _changeDay(picked);
  }

  Future<bool> _confirmDelete(Sale sale) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Savdoni o'chirasizmi?"),
        content: Text(formatMoney(sale.amount)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("O'chirish")),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Hisobdan chiqish (tasdiqlash bilan)
  Future<void> _logout() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hisobdan chiqasizmi?'),
        content: Text(email),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Yo'q")),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ha, chiqish')),
        ],
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunlik savdolar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Chiqish',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSaleSheet.show(context, date: _day),
        icon: const Icon(Icons.add),
        label: const Text("Savdo qo'shish"),
      ),
      body: Column(
        children: [
          _buildDateBar(),
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sales = snapshot.data!;
                return Column(
                  children: [
                    _buildSummary(sales),
                    Expanded(
                      child: sales.isEmpty
                          ? const Center(child: Text("Bu kunda savdo yo'q"))
                          : _buildList(sales),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Kunni almashtirish paneli: < 11.10.2026 >
  Widget _buildDateBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                _changeDay(DateTime(_day.year, _day.month, _day.day - 1)),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _isToday ? 'Bugun, ${formatDate(_day)}' : formatDate(_day),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday
                ? null
                : () =>
                    _changeDay(DateTime(_day.year, _day.month, _day.day + 1)),
          ),
        ],
      ),
    );
  }

  /// Yuqoridagi jami summa kartasi
  Widget _buildSummary(List<Sale> sales) {
    final cs = Theme.of(context).colorScheme;
    double sumOf(PaymentType t) => sales
        .where((s) => s.paymentType == t)
        .fold(0.0, (sum, s) => sum + s.amount);
    final total = sales.fold(0.0, (sum, s) => sum + s.amount);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Jami savdo',
                style: TextStyle(color: cs.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(
              formatMoney(total),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Naqd', sumOf(PaymentType.cash)),
                _miniStat('Karta', sumOf(PaymentType.card)),
                _miniStat('Qarz', sumOf(PaymentType.debt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String title, double value) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 2),
        Text(formatMoney(value),
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  /// Savdolar ro'yxati (chapga surib o'chirish mumkin)
  Widget _buildList(List<Sale> sales) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90), // tugma ostida qolmasin
      itemCount: sales.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final sale = sales[i];
        return Dismissible(
          key: ValueKey(sale.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(sale),
          onDismissed: (_) => _service.deleteSale(sale.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading: CircleAvatar(child: Icon(_iconFor(sale.paymentType))),
            title: Text(sale.note.isEmpty ? 'Savdo' : sale.note),
            subtitle: Text([
              formatTime(sale.createdAt),
              sale.paymentType.label,
              if (sale.customerName != null) sale.customerName!,
            ].join(' • ')),
            trailing: Text(
              formatMoney(sale.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: sale.paymentType == PaymentType.debt
                    ? Colors.red.shade700
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(PaymentType t) {
    switch (t) {
      case PaymentType.cash:
        return Icons.payments_outlined;
      case PaymentType.card:
        return Icons.credit_card;
      case PaymentType.debt:
        return Icons.person_outline;
    }
  }
}
