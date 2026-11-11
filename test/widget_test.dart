import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:podomoro_timer/main.dart';

void main() {
  testWidgets('Timer starts at 25:00 and counts down', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:59'), findsOneWidget);

    await tester.tap(find.text('Pause')); // stop the timer before the test ends
    await tester.pump();
  });

  testWidgets('Next skips the focus session to a short break', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Short Break'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('Settings page shows the presets', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Standard 25/5/15'), findsOneWidget);
    expect(find.text('Long 50/10/30'), findsOneWidget);
  });
}