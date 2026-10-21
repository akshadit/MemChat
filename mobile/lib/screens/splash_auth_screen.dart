import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import '../theme/app_theme.dart';
import 'chat_list_screen.dart';

class SplashAuthScreen extends StatefulWidget {
  const SplashAuthScreen({super.key});

  @override
  State<SplashAuthScreen> createState() => _SplashAuthScreenState();
}

class _SplashAuthScreenState extends State<SplashAuthScreen> {
  @override
  void initState() {
    super.initState();
    GoogleAuthService.instance.init().then((_) {
      if (GoogleAuthService.instance.isSignedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = GoogleAuthService.instance;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Icon Badge
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.whatsappGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.whatsappGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 44,
                    color: AppTheme.whatsappGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'MemChat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),

              // Subtitle specifically addressing older / non-tech users
              Text(
                'Your Google Drive, turned into simple chats.\nNo confusing folders. Just chat with your files.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
              ),

              const SizedBox(height: 24),

              // Value Props Strip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      Icons.folder_shared_outlined,
                      'Your Actual Google Drive',
                      'Folders appear as chats. Everything stays in your own Drive.',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      Icons.share_outlined,
                      'WhatsApp Forward Friendly',
                      'Forward any photo, bill, or PDF directly from WhatsApp to a chat.',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      Icons.lock_outline_rounded,
                      '100% Private & Free',
                      'No middleman servers. We never see or store your files.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final success = await auth.signIn();
                          if (success && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const ChatListScreen(),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsappGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.g_mobiledata_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Explore Demo Mode Shortcut
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ChatListScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Explore Demo Mode (No Google Account needed)',
                  style: TextStyle(
                    color: AppTheme.primaryEmerald,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.whatsappGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
