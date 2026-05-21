import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/core/shared_widgets/app_button.dart';

void main() {
  testWidgets('each button variant triggers its action', (tester) async {
    final pressed = <AppButtonVariant>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: AppButtonVariant.values
                .map(
                  (variant) => AppButton(
                    text: variant.name,
                    variant: variant,
                    enableHaptic: false,
                    onPressed: () => pressed.add(variant),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    for (final variant in AppButtonVariant.values) {
      await tester.tap(find.text(variant.name));
      await tester.pumpAndSettle();
    }

    expect(pressed, AppButtonVariant.values);
  });

  testWidgets('loading state shows a spinner and blocks the action', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Submit',
            isLoading: true,
            enableHaptic: false,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(pressed, isFalse);
  });

  testWidgets('renders icon buttons with both icon and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Continue',
            icon: Icons.arrow_forward,
            enableHaptic: false,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
