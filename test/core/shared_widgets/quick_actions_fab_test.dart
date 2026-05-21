import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/core/shared_widgets/quick_actions_fab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('collapsed quick actions do not trigger hidden actions', (
    tester,
  ) async {
    var editTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: QuickActionsFab(
            actions: [
              QuickActionItem(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () => editTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(editTapped, isFalse);
  });

  testWidgets('expanded quick action runs its callback and collapses', (
    tester,
  ) async {
    var editTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: QuickActionsFab(
            actions: [
              QuickActionItem(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () => editTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(editTapped, isTrue);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('simple fab triggers the callback with and without label', (
    tester,
  ) async {
    var iconOnlyTapped = false;
    var labeledTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SimpleFab(
                icon: Icons.add,
                onTap: () => iconOnlyTapped = true,
              ),
              SimpleFab(
                icon: Icons.send,
                label: 'Send',
                onTap: () => labeledTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(iconOnlyTapped, isTrue);
    expect(labeledTapped, isTrue);
  });
}
