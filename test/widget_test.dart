import 'package:dhanviq/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DHANVIQ splash screen loads correctly', (tester) async {
    await tester.pumpWidget(const DhanviqApp());

    expect(find.text('DHANVIQ'), findsOneWidget);
    expect(find.text('Track  •  Save  •  Grow'), findsOneWidget);

    // Complete splash timer and navigation animation.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('DHANVIQ'), findsOneWidget);
  });
}