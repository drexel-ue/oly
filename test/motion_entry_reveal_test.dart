import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OlyEntryReveal Widget Tests', () {
    testWidgets('renders child instantly in test mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OlyEntryReveal(
              child: Text('Revealed Content'),
            ),
          ),
        ),
      );

      expect(find.text('Revealed Content'), findsOneWidget);
    });

    testWidgets('supports custom index, delay, and reverse options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                OlyEntryReveal(
                  index: 1,
                  waitForPageTransition: false,
                  reverseOnExit: false,
                  child: Text('Card 1'),
                ),
                OlyEntryReveal(
                  index: 2,
                  reverseDelay: Duration(milliseconds: 40),
                  child: Text('Card 2'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
    });
  });
}
