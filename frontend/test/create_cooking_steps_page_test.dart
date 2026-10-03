import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sections have independent titles and steps stay numbered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CreateCookingStepsPage()));

    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'วิธีทำ');
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byTooltip('พับรายละเอียด'), findsOneWidget);
    expect(find.text('สื่อประกอบ'), findsNothing);
    expect(find.text('ขั้นตอนที่ 1'), findsOneWidget);

    final stepTypeDropdown = find.byType(DropdownButtonFormField<String>);
    expect(stepTypeDropdown, findsOneWidget);
    await tester.tap(stepTypeDropdown);
    await tester.pumpAndSettle();
    expect(find.text('รูปภาพ'), findsOneWidget);
    expect(find.text('คลิปวิดีโอ'), findsOneWidget);
    await tester.tap(find.text('เคล็ดลับ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มขั้นตอน'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มขั้นตอน'), findsOneWidget);
    expect(find.text('ขั้นตอนที่ 2'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(7));

    await tester.tap(find.text('เพิ่มหัวข้อชุดขั้นตอน'));
    await tester.pumpAndSettle();
    expect(find.text('ขั้นตอนที่ 3'), findsOneWidget);
    expect(find.text('เพิ่มขั้นตอน'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(8));

    await tester.enterText(find.byType(TextFormField).last, 'เคล็ดลับ');
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(11));

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields.first.controller!.text, 'วิธีทำ');
    expect(fields[7].controller!.text, 'เคล็ดลับ');

    await tester.tap(find.byTooltip('พับรายละเอียด').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(8));

    await tester.tap(find.byTooltip('ขยายรายละเอียด').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(11));
  });
}
