import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_auth_screen.dart';
import 'services/share_intent_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to match dark WhatsApp aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkCanvas,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize the native share intent interceptor (WhatsApp forward receiver)
  ShareIntentService.instance.init();

  runApp(const MemChatApp());
}

class MemChatApp extends StatelessWidget {
  const MemChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashAuthScreen(),
    );
  }
}
