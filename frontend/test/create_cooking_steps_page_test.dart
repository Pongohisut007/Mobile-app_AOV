import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('section cards open a separate page for their steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CreateCookingStepsPage()));
    expect(find.text('ขั้นตอนที่ 1'), findsNothing);

    await tester.tap(find.text('เพิ่มหัวข้อขั้นตอน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'วิธีทำ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('วิธีทำ')),
      findsOneWidget,
    );
    expect(find.text('ขั้นตอนที่ 1'), findsOneWidget);
    expect(find.text('เพิ่มหัวข้อขั้นตอน'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));

    await tester.enterText(find.byType(TextFormField).at(0), 'เตรียมวัตถุดิบ');
    await tester.enterText(find.byType(TextFormField).at(1), 'หั่นและเตรียม');
    await tester.tap(find.text('เพิ่มขั้นตอน'));
    await tester.pumpAndSettle();
    expect(find.text('ขั้นตอนที่ 2'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), 'ผัดเครื่องปรุง');
    await tester.enterText(find.byType(TextFormField).at(4), 'ตั้งกระทะและผัด');
    await tester.tap(find.byTooltip('กลับ (บันทึกอัตโนมัติ)'));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอนที่ 1'), findsOneWidget);
    expect(find.text('ขั้นตอนที่ 2'), findsOneWidget);
    expect(find.text('เตรียมวัตถุดิบ'), findsOneWidget);
    expect(find.text('ผัดเครื่องปรุง'), findsOneWidget);

    await tester.tap(find.text('เพิ่มหัวข้อขั้นตอน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'เคล็ดลับ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('เคล็ดลับ')),
      findsOneWidget,
    );
    expect(find.text('ขั้นตอนที่ 3'), findsOneWidget);
    expect(find.text('เพิ่มหัวข้อขั้นตอน'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'โรยต้นหอม');
    await tester.enterText(find.byType(TextFormField).at(1), 'จัดเสิร์ฟ');
    await tester.tap(find.byTooltip('กลับ (บันทึกอัตโนมัติ)'));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอนที่ 3'), findsOneWidget);
    expect(find.text('โรยต้นหอม'), findsOneWidget);
  });
}
