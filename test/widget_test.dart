import 'package:flutter_test/flutter_test.dart';
import 'package:herbacat/main.dart';

void main() {
  testWidgets('HerbaCatApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HerbaCatApp());
    expect(find.text('Welcome to HerbaCat'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
