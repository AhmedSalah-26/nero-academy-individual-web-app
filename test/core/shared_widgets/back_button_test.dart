import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';

void main() {
  testWidgets('calls custom callback when provided', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: AppBackButton(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });

  testWidgets('pops the current route when no callback is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const _FirstScreen(),
        routes: {
          '/details': (_) => const _DetailsScreen(),
        },
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Details'), findsNothing);
  });
}

class _FirstScreen extends StatelessWidget {
  const _FirstScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text('Home'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/details'),
            child: const Text('Open details'),
          ),
        ],
      ),
    );
  }
}

class _DetailsScreen extends StatelessWidget {
  const _DetailsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
      ),
      body: const Center(
        child: Text('Details'),
      ),
    );
  }
}
