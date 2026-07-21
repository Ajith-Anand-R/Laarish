import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/app/providers.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/data/repositories.dart';
import 'package:laarish/features/level_engine/plant_complete_screen.dart';

class _FakeRepo implements ProgressRepository {
  @override
  Future<GameSave> load() async => GameSave.empty();
  @override
  Future<void> save(GameSave save) async {}
}

void main() {
  testWidgets('plant complete screen renders the harvest celebration', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(_FakeRepo())],
        child: const MaterialApp(home: PlantCompleteScreen(plantId: 'tommy')),
      ),
    );
    // Confetti + flutter_animate tickers never settle — use fixed pumps.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull);
    expect(find.text('You grew Tommy!'), findsOneWidget);
    expect(find.text('Back to my journey'), findsOneWidget);
  });
}
