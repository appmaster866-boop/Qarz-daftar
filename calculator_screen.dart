import 'package:flutter/material.dart';

import '../utils/format.dart';
import '../widgets/add_sale_sheet.dart';

/// Oddiy kalkulyator + natijani bevosita savdo sifatida saqlash tugmasi.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0'; // ekrandagi joriy son
  String _expression = ''; // yuqoridagi kichik ifoda, masalan "12 + 3 ="
  double? _first; // birinchi operand
  String? _operator; // + − × ÷
  bool _startNew = false; // keyingi raqam yangi son boshlaydimi?

  double get _current => double.tryParse(_display) ?? 0;
  bool get _hasError => _display == 'Xato';

  // ---------- LOGIKA ----------

  /// Sonni chiroyli matnga aylantiradi: 5.0 -> "5", 0.50000000 -> "0.5"
  String _fmt(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// Hisoblash. Nolga bo'lishda null qaytaradi (xato).
  double? _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? null : a / b;
    }
    return b;
  }

  void _showError() {
    _display = 'Xato';
    _expression = '';
    _first = null;
    _operator = null;
    _startNew = true;
  }

  void _onDigit(String d) {
    setState(() {
      if (_startNew || _display == '0' || _hasError) {
        if (_startNew && _operator == null) _expression = '';
        _display = d == '00' ? '0' : d;
        _startNew = false;
      } else if (_display.replaceAll(RegExp(r'[-.]'), '').length < 12) {
        _display += d; // 12 ta raqamdan ortiq kiritmaymiz
      }
    });
  }

  void _onDot() {
    setState(() {
      if (_startNew || _hasError) {
        _display = '0.';
        _startNew = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    if (_hasError) return;
    setState(() {
      if (_first != null && _operator != null && !_startNew) {
        // Zanjirli hisob: 5 + 3 + ... -> avval 5+3 hisoblanadi
        final r = _calculate(_first!, _current, _operator!);
        if (r == null) {
          _showError();
          return;
        }
        _first = r;
        _display = _fmt(r);
      } else {
        _first = _current;
      }
      _operator = op;
      _startNew = true;
      _expression = '${groupDigits(_fmt(_first!))} $op';
    });
  }

  void _onEquals() {
    if (_first == null || _operator == null || _hasError) return;
    setState(() {
      final second = _current;
      final r = _calculate(_first!, second, _operator!);
      if (r == null) {
        _showError();
        return;
      }
      _expression =
          '${groupDigits(_fmt(_first!))} $_operator ${groupDigits(_fmt(second))} =';
      _display = _fmt(r);
      _first = null;
      _operator = null;
      _startNew = true;
    });
  }

  void _onPercent() {
    if (_hasError) return;
    setState(() => _display = _fmt(_current / 100));
  }

  void _onBackspace() {
    if (_hasError || _startNew) return;
    setState(() {
      final isSingle = _display.length == 1 ||
          (_display.length == 2 && _display.startsWith('-'));
      _display = isSingle ? '0' : _display.substring(0, _display.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _first = null;
      _operator = null;
      _startNew = false;
    });
  }

  /// Natijani savdo sifatida saqlash oynasini ochadi
  Future<void> _saveAsSale() async {
    final saved = await AddSaleSheet.show(context, initialAmount: _current);
    // Saqlangan bo'lsa kalkulyatorni tozalaymiz (bir xil savdo qayta yozilmasin)
    if (saved == true && mounted) _onClear();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulyator')),
      body: SafeArea(
        child: Column(
          children: [
            // Ekran
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: TextStyle(fontSize: 20, color: cs.outline),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        groupDigits(_display),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // "Savdoga qo'shish" tugmasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: (_current > 0 && !_hasError) ? _saveAsSale : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Savdoga qo'shish"),
                ),
              ),
            ),

            // Tugmalar paneli
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: [
                    _row([
                      _key(const Text('C'), _onClear, kind: _Kind.action),
                      _key(const Icon(Icons.backspace_outlined), _onBackspace,
                          kind: _Kind.action),
                      _key(const Text('%'), _onPercent, kind: _Kind.action),
                      _key(const Text('÷'), () => _onOperator('÷'),
                          kind: _Kind.operator),
                    ]),
                    _row([
                      _key(const Text('7'), () => _onDigit('7')),
                      _key(const Text('8'), () => _onDigit('8')),
                      _key(const Text('9'), () => _onDigit('9')),
                      _key(const Text('×'), () => _onOperator('×'),
                          kind: _Kind.operator),
                    ]),
                    _row([
                      _key(const Text('4'), () => _onDigit('4')),
                      _key(const Text('5'), () => _onDigit('5')),
                      _key(const Text('6'), () => _onDigit('6')),
                      _key(const Text('−'), () => _onOperator('−'),
                          kind: _Kind.operator),
                    ]),
                    _row([
                      _key(const Text('1'), () => _onDigit('1')),
                      _key(const Text('2'), () => _onDigit('2')),
                      _key(const Text('3'), () => _onDigit('3')),
                      _key(const Text('+'), () => _onOperator('+'),
                          kind: _Kind.operator),
                    ]),
                    _row([
                      _key(const Text('00'), () => _onDigit('00')),
                      _key(const Text('0'), () => _onDigit('0')),
                      _key(const Text('.'), _onDot),
                      _key(const Text('='), _onEquals, kind: _Kind.equals),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) =>
      Expanded(child: Row(children: children));

  Widget _key(Widget child, VoidCallback onTap, {_Kind kind = _Kind.number}) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (kind) {
      case _Kind.number:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        break;
      case _Kind.action:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        break;
      case _Kind.operator:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case _Kind.equals:
        bg = cs.primary;
        fg = cs.onPrimary;
        break;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum _Kind { number, action, operator, equals }
