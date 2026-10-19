import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegister) {
        await controller.register(email, password);
      } else {
        await controller.login(email, password);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final sessionExpired = ref.watch(authControllerProvider).sessionExpired;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TaskBell',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Plus Jakarta Sans',
                      fontVariations: [FontVariation('wght', 900)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola tugas kuliah dan harianmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted),
                  ),
                  const SizedBox(height: 24),
                  ComicCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isRegister ? 'Buat Akun' : 'Masuk',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (sessionExpired && !_isRegister) ...[
                            _buildInfo(
                              palette,
                              'Sesi Anda berakhir. Silakan masuk kembali.',
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              hintText: 'nama@kampus.ac.id',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Email wajib diisi';
                              final pattern = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!pattern.hasMatch(email)) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Password'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: _isRegister
                                  ? 'Minimal 8 karakter'
                                  : 'Password kamu',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
                                icon: AppIcon(
                                  _obscurePassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (_isRegister && password.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: palette.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ComicButton(
                            text: _isSubmitting
                                ? 'Memproses...'
                                : (_isRegister ? 'Daftar' : 'Masuk'),
                            onPressed: _isSubmitting ? () {} : _submit,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSubmitting ? null : _toggleMode,
                            child: Text(
                              _isRegister
                                  ? 'Sudah punya akun? Masuk'
                                  : 'Belum punya akun? Daftar',
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildInfo(AppPalette palette, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
