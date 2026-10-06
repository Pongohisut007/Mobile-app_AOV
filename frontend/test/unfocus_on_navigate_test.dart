import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/unfocus_on_navigate_observer.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required List<NavigatorObserver> observers}) {
  return MaterialApp(
    navigatorObservers: observers,
    home: Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            const TextField(key: Key('title')),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('steps page')),
                ),
              ),
              child: const Text('open page'),
            ),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(key: Key('sheet field'), autofocus: true),
                ),
              ),
              child: const Text('open sheet'),
            ),
          ],
        ),
      ),
    ),
  );
}

bool _titleHasFocus(WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const Key('title')),
      matching: find.byType(EditableText),
    ),
  );
  return editable.focusNode.hasFocus;
}

void main() {
  testWidgets('without the observer Flutter gives focus back (the bug)', (
    tester,
  ) async {
    await tester.pumpWidget(_app(observers: const []));
    await tester.tap(find.byKey(const Key('title')));
    await tester.pump();
    expect(_titleHasFocus(tester), isTrue);

    await tester.tap(find.text('open page'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(_titleHasFocus(tester), isTrue);
  });

  testWidgets('coming back from another page does not refocus the field', (
    tester,
  ) async {
    await tester.pumpWidget(_app(observers: [UnfocusOnNavigateObserver()]));
    await tester.tap(find.byKey(const Key('title')));
    await tester.pump();
    expect(_titleHasFocus(tester), isTrue);

    await tester.tap(find.text('open page'));
    await tester.pumpAndSettle();
    expect(find.text('steps page'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(_titleHasFocus(tester), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a bottom sheet can still focus its own field', (tester) async {
    await tester.pumpWidget(_app(observers: [UnfocusOnNavigateObserver()]));
    await tester.tap(find.byKey(const Key('title')));
    await tester.pump();

    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();

    final sheetField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('sheet field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(sheetField.focusNode.hasFocus, isTrue);
    expect(_titleHasFocus(tester), isFalse);

    // ปิดชีตแล้ว ช่องเดิมในหน้าไม่ได้ focus กลับมา
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(_titleHasFocus(tester), isFalse);
  });
}
