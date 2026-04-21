import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/pages/onboarding/firma_kayit_page.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class RegisterPage extends StatefulWidget {
  final AbonelikPlani? secilenPlan;
  final bool yillik;

  const RegisterPage({
    super.key,
    this.secilenPlan,
    this.yillik = false,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (!mounted) return;
        context.showSnackBar('Kayit basarili.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FirmaKayitPage(
              secilenPlan: widget.secilenPlan,
              yillik: widget.yillik,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      var mesaj = 'Kayit hatasi';
      final hata = e.toString();
      if (hata.contains('already registered') ||
          hata.contains('already exists')) {
        mesaj = 'Bu e-posta adresi zaten kayitli';
      } else if (hata.contains('password')) {
        mesaj = 'Parola en az 6 karakter olmalidir';
      } else if (hata.contains('email')) {
        mesaj = 'Gecersiz e-posta adresi';
      } else {
        mesaj = 'Kayit hatasi: $e';
      }
      context.showSnackBar(mesaj);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Olustur')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kIsWeb ? 450 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(kIsWeb ? 40.0 : 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_rounded,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TexPilot kaydi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '14 gun ucretsiz deneme, tum moduller dahil',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'E-posta gerekli';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Gecerli bir e-posta girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Parola',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Parola gerekli';
                      }
                      if (v.length < 6) {
                        return 'Parola en az 6 karakter olmali';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordConfirmController,
                    decoration: const InputDecoration(
                      labelText: 'Parola Tekrar',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v != passwordController.text) {
                        return 'Parolalar eslesmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : _register,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Hesap Olustur',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zaten hesabiniz var mi? Giris yapin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
