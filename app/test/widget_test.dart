import 'package:flutter_test/flutter_test.dart';
import 'package:mocgb/main.dart';

void main() {
  testWidgets('hub shows the club sections', (tester) async {
    await tester.pumpWidget(const MocgbApp());
    expect(find.text('Next event'), findsOneWidget);
    expect(find.text('Contact the club'), findsOneWidget);
  });
}
