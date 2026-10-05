import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/fade_indexed_stack.dart';
import 'package:flutter_test/flutter_test.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('${widget.name}:$_count'),
    );
  }
}

Widget _app(int index) => MaterialApp(
  home: Scaffold(
    body: FadeIndexedStack(
      index: index,
      children: const [_Counter('a'), _Counter('b')],
    ),
  ),
);

void main() {
  testWidgets('switching tabs fades in and keeps each tab state', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.tap(find.text('a:0'));
    await tester.pump();
    expect(find.text('a:1'), findsOneWidget);
    // แท็บที่ซ่อนอยู่ไม่แสดงและแตะไม่ได้
    expect(find.text('b:0'), findsNothing);

    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(milliseconds: 60));
    final opacity = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('b:0'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(opacity, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.text('a:1'), findsNothing);

    // กลับมาแท็บแรก ค่าที่กดไว้ยังอยู่ (ไม่ได้สร้างหน้าใหม่)
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(find.text('a:1'), findsOneWidget);
  });
}
