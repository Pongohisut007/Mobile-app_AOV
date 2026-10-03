import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/pages/create_foodcard_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('back asks before leaving a form with entered data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: const Center(child: Text('หน้าก่อน')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const CreateFoodcardPage(categories: []),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'สูตรทดสอบ');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('บันทึกฉบับร่างก่อนออกไหม?'), findsOneWidget);

    await tester.tap(find.text('อยู่ต่อ'));
    await tester.pumpAndSettle();
    expect(find.text('สร้างสูตรอาหาร'), findsOneWidget);
    expect(find.text('บันทึกฉบับร่างก่อนออกไหม?'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกโดยไม่บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('หน้าก่อน'), findsOneWidget);
    expect(find.text('สร้างสูตรอาหาร'), findsNothing);
  });
}
