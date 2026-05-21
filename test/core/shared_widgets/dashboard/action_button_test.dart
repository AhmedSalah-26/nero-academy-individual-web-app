import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/action_button.dart';

void main() {
  testWidgets('solid action button runs its callback', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SolidActionButton(
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.blue,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });

  testWidgets('solid action button disables press while loading', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SolidActionButton(
            icon: Icons.delete,
            label: 'Delete',
            color: Colors.red,
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Delete'), warnIfMissed: false);
    await tester.pump();

    expect(pressed, isFalse);
  });

  testWidgets('solid action chip runs its callback', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SolidActionChip(
            icon: Icons.share,
            label: 'Share',
            color: Colors.green,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });

  testWidgets('vertical action button runs its callback', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerticalActionButton(
            icon: Icons.download,
            label: 'Download',
            color: Colors.orange,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });
}
