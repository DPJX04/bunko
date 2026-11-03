import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/widgets/fade_through_stack.dart';

/// A tab body that counts taps, so a test can see its state survive.
class Counter extends StatefulWidget {
  const Counter({super.key, required this.name});

  final String name;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => taps++),
      child: Text('${widget.name} $taps'),
    );
  }
}

/// Wraps the stack in an app, optionally with Remove animations turned on.
Widget harness(int index, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: FadeThroughStack(
        index: index,
        children: const [
          Counter(name: 'a'),
          Counter(name: 'b'),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('a hidden tab keeps its state', (tester) async {
    await tester.pumpWidget(harness(0));
    await tester.tap(find.text('a 0'));
    await tester.pump();
    expect(find.text('a 1'), findsOneWidget);

    await tester.pumpWidget(harness(1));
    await tester.pumpAndSettle();
    expect(find.text('b 0'), findsOneWidget);
    expect(find.text('a 1'), findsNothing);

    await tester.pumpWidget(harness(0));
    await tester.pumpAndSettle();
    expect(find.text('a 1'), findsOneWidget);
  });

  testWidgets('only the open tab takes taps', (tester) async {
    await tester.pumpWidget(harness(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('b 0'));
    await tester.pump();
    expect(find.text('b 1'), findsOneWidget);
  });

  testWidgets('Remove animations makes the switch instant', (tester) async {
    await tester.pumpWidget(harness(0, reduceMotion: true));
    await tester.pumpWidget(harness(1, reduceMotion: true));
    await tester.pump();
    expect(find.text('b 0'), findsOneWidget);
    expect(find.text('a 0'), findsNothing);
  });
}
