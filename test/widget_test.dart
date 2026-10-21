import 'package:flutter_test/flutter_test.dart';
import 'package:memchat/main.dart';

void main() {
  testWidgets('MemChatApp smoke test renders SplashAuthScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MemChatApp());
    expect(find.text('MemChat'), findsOneWidget);
    expect(find.text('Explore Demo Mode (No Google Account needed)'), findsOneWidget);
  });
}
