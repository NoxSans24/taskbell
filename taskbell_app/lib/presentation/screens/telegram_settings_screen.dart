import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/presentation/screens/backup_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class TelegramSettingsScreen extends ConsumerStatefulWidget {
  const TelegramSettingsScreen({super.key});

  @override
  ConsumerState<TelegramSettingsScreen> createState() =>
      _TelegramSettingsScreenState();
}

class _TelegramSettingsScreenState
    extends ConsumerState<TelegramSettingsScreen> {
  final _botTokenController = TextEditingController();
  final _chatIdController = TextEditingController();

  bool _isConnected = false;
  bool _isLoadingStatus = true;
  bool _isBusy = false;
  String? _maskedChatId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ref.read(apiClientProvider).fetchTelegramLink();

      if (!mounted) return;
      setState(() {
        _isConnected = data['connected'] == true && data['enabled'] == true;
        _maskedChatId = data['chatId'] as String?;
        _isLoadingStatus = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingStatus = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStatus = false;
        _error = 'Gagal memuat status Telegram.';
      });
    }
  }

  Future<void> _saveLink() async {
    final botToken = _botTokenController.text.trim();
    final chatId = _chatIdController.text.trim();

    if (botToken.isEmpty || chatId.isEmpty) {
      setState(() => _error = 'Token Bot dan Chat ID wajib diisi.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final data = await ref.read(apiClientProvider).saveTelegramLink(
            botToken: botToken,
            chatId: chatId,
          );

      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _maskedChatId = data['chatId'] as String?;
        _isBusy = false;
      });
      _botTokenController.clear();
      _showMessage('Telegram terhubung. Pesan uji telah dikirim.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _sendTest() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await ref.read(apiClientProvider).sendTelegramTest();

      if (!mounted) return;
      setState(() => _isBusy = false);
      _showMessage('Pesan uji terkirim ke Telegram.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await ref.read(apiClientProvider).deleteTelegramLink();

      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _maskedChatId = null;
        _isBusy = false;
      });
      _botTokenController.clear();
      _chatIdController.clear();
      _showMessage('Koneksi Telegram diputuskan.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = error.message;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Integrasi Telegram",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComicCard(
              color: const Color(0xFF2AABEE),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppIcon(
                    AppIcons.send,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Telegram Bot",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _isLoadingStatus
                              ? "Memuat status..."
                              : _isConnected
                                  ? "Terhubung ke ${_maskedChatId ?? '****'}"
                                  : "Belum terhubung",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingStatus)
              Text(
                'Memuat status Telegram...',
                style: TextStyle(color: palette.muted),
              )
            else if (_isConnected) ...[
              Text(
                'Pengingat tugas akan dikirim ke chat Telegram ini saat '
                'tenggat tiba, walaupun aplikasi ditutup.',
                style: TextStyle(color: palette.muted),
              ),
              const SizedBox(height: 16),
              ComicButton(
                text: _isBusy ? "Memproses..." : "Kirim Pesan Uji",
                onPressed: _isBusy ? () {} : _sendTest,
              ),
              const SizedBox(height: 12),
              ComicButton(
                text: "Putus Koneksi",
                color: palette.errorSoft,
                onPressed: _isBusy ? () {} : _disconnect,
              ),
            ] else ...[
              const Text(
                "Bot Token",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ComicCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _botTokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Masukkan Token Bot",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Chat ID",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ComicCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _chatIdController,
                  decoration: const InputDecoration(
                    hintText: "Masukkan Chat ID",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ComicButton(
                text: _isBusy ? "Memproses..." : "Simpan & Tes Koneksi",
                onPressed: _isBusy ? () {} : _saveLink,
              ),
            ],
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
            const SizedBox(height: 16),
            ComicButton(
              text: "Backup & Restore",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ComicCard(
              color: palette.secondarySoft,
              padding: const EdgeInsets.all(12),
              child: Text(
                "Info: Dapatkan token dari @BotFather dan Chat ID dari "
                "@userinfobot. Token disimpan terenkripsi di server dan "
                "tidak disimpan di perangkat.",
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
