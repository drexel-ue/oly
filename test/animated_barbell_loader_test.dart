import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/widgets/motion/animated_barbell_loader.dart';

void main() {
  testWidgets('AnimatedBarbellLoader renders full barbell with default KG plates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedBarbellLoader(
            targetWeight: 100,
            showBreakdownChips: true,
          ),
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(AnimatedBarbellLoader), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Fast-forward entry animation to complete
    await tester.pumpAndSettle();
    expect(find.text('20kg bar'), findsOneWidget);
  });

  testWidgets('AnimatedBarbellLoader renders single sleeve mode with chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedBarbellLoader(
            targetWeight: 140,
            displayMode: BarbellDisplayMode.singleSleeve,
            showBreakdownChips: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBarbellLoader), findsOneWidget);
    expect(find.text('20kg bar'), findsOneWidget);
    expect(find.text('+collars'), findsOneWidget);
  });

  testWidgets('AnimatedBarbellLoader updates smoothly when targetWeight changes', (
    tester,
  ) async {
    double currentWeight = 100;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  AnimatedBarbellLoader(
                    targetWeight: currentWeight,
                    showBreakdownChips: true,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => currentWeight = 140),
                    child: const Text('Add Weight'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBarbellLoader), findsOneWidget);

    // Tap to increase weight
    await tester.tap(find.text('Add Weight'));
    await tester.pump(); // Start morph animation
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle(); // Settle morph animation

    expect(find.byType(AnimatedBarbellLoader), findsOneWidget);
  });

  testWidgets('AnimatedBarbellLoader triggers onTap callback when tapped', (
    tester,
  ) async {
    bool wasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBarbellLoader(
            targetWeight: 100,
            onTap: () => wasTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(AnimatedBarbellLoader));
    expect(wasTapped, isTrue);
  });

  testWidgets('AnimatedBarbellLoader re-runs animation on weight adjustment', (
    tester,
  ) async {
    double weight = 80;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  AnimatedBarbellLoader(
                    targetWeight: weight,
                  ),
                  TextButton(
                    onPressed: () => setState(() => weight = 120),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    // Trigger manual weight change
    await tester.tap(find.text('Change'));
    await tester.pump(); // frame 0 of re-run animation

    // Verify it is animating
    expect(tester.hasRunningAnimations, isTrue);

    // Advance 300ms (mid-flight)
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isTrue);

    // Let it complete
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
