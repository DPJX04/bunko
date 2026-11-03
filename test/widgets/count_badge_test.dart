import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';
import 'package:light_novel_downloader/widgets/count_badge.dart';

void main() {
  Future<void> show(WidgetTester tester, int count) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Center(
          child: CountBadge(count: count, child: const Icon(Icons.download)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the count over its child', (tester) async {
    await show(tester, 3);

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('is hidden at zero', (tester) async {
    await show(tester, 0);

    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('is a legend-coloured plate with ink digits', (tester) async {
    await show(tester, 2);

    final scheme = AppTheme.dark.colorScheme;
    final plate = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('2'), matching: find.byType(DecoratedBox)),
    );
    final decoration = plate.decoration as BoxDecoration;
    expect(decoration.color, scheme.onSurface);
    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(2)));
    final digits = tester.widget<Text>(find.text('2'));
    expect(digits.style?.color, scheme.surface);
  });
}
