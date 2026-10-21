import 'package:flutter_test/flutter_test.dart';
import 'package:memchat/main.dart';

void main() {
  testWidgets('MemChatApp smoke test renders SplashAuthScreen with WhatsApp aesthetics', (WidgetTester tester) async {
    await tester.pumpWidget(const MemChatApp());
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('MemChat'), findsOneWidget);
    expect(find.text('Explore Demo Mode (No Setup Required)'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
