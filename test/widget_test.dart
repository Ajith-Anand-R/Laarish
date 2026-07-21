import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/app/app.dart';
import 'package:laarish/features/onboarding/splash_screen.dart';

void main() {
  testWidgets('app boots to splash without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaarishApp()));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget); // splash shows the logo
    await tester.pump(const Duration(milliseconds: 1300)); // let the splash timer fire
    await tester.pump(const Duration(milliseconds: 500)); // settle the /login navigation
  });
}
