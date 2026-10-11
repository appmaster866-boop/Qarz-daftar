import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Kirish / Ro'yxatdan o'tish ekrani (email + parol).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false; // false = kirish, true = ro'yxatdan o'tish
  bool _loading = false;
  bool _hidePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Firebase xato kodlarini o'zbekchaga o'giradi
  String _errorText(String code) {
    switch (code) {
      case 'invalid-email':
        return "Email manzili noto'g'ri yozilgan";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Email yoki parol noto'g'ri";
      case 'email-already-in-use':
        return "Bu email bilan allaqachon ro'yxatdan o'tilgan. \"Kirish\" ni tanlang";
      case 'weak-password':
        return "Parol juda oddiy (kamida 6 ta belgi bo'lsin)";
      case 'network-request-failed':
        return "Internet yo'q. Aloqani tekshiring";
      case 'too-many-requests':
        return "Juda ko'p urinish. Birozdan keyin qayta urinib ko'ring";
      case 'operation-not-allowed':
        return "Firebase da Email/Parol orqali kirish yoqilmagan";
      default:
        return "Xatolik: $code";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      if (_isRegister) {
        await auth.createUserWithEmailAndPassword(email: email, password: pass);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
      }
      // Muvaffaqiyatli bo'lsa AuthGate o'zi asosiy ekranga o'tkazadi.
    } on FirebaseAuthException catch (e) {
      _showMessage(_errorText(e.code));
    } catch (_) {
      _showMessage("Kutilmagan xatolik. Qayta urinib ko'ring");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Avval email manzilingizni kiriting');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Parolni tiklash xati $email manziliga yuborildi');
    } on FirebaseAuthException catch (e) {
      _showMessage(_errorText(e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 72, color: cs.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Qarz Daftar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegister
                            ? "Yangi hisob yarating"
                            : "Hisobingizga kiring",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.outline),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty || !t.contains('@') || !t.contains('.')) {
                            return "To'g'ri email kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _hidePass,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Parol',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_hidePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _hidePass = !_hidePass),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Parol kamida 6 ta belgi bo\'lsin'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isRegister ? "Ro'yxatdan o'tish" : 'Kirish'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister
                            ? "Hisobim bor, kirish"
                            : "Hisobim yo'q, ro'yxatdan o'tish"),
                      ),
                      if (!_isRegister)
                        TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: const Text('Parolni unutdingizmi?'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
