import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocgb/club_data.dart';
import 'package:mocgb/main.dart';

void main() {
  testWidgets('tabs switch between the club sections', (tester) async {
    await tester.pumpWidget(MocgbApp(data: ClubData()));
    expect(find.text('Next event'), findsOneWidget);

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();
    expect(find.text('membership@mocgb.net'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
  });
}
