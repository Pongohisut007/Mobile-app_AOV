import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/pages/create_cooking_steps_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'each step has an independent section title and collapsible details',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CreateCookingStepsPage()),
      );

      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'วิธีทำ');
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byTooltip('พับรายละเอียด'), findsOneWidget);
      expect(find.text('สื่อประกอบ'), findsNothing);

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
      expect(find.byType(TextFormField), findsNWidgets(5));

      await tester.enterText(find.byType(TextFormField).at(4), 'เคล็ดลับ');
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(8));

      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[0].controller!.text, 'วิธีทำ');
      expect(fields[4].controller!.text, 'เคล็ดลับ');

      await tester.tap(find.byTooltip('พับรายละเอียด').first);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(5));

      await tester.tap(find.byTooltip('ขยายรายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(8));
    },
  );
}
