import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/route_transition_aware.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.data});

  final Future<String> data;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with RouteTransitionAware {
  String? _value;

  @override
  void initState() {
    super.initState();
    afterRouteTransition(widget.data).then((value) {
      if (mounted) setState(() => _value = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${isRouteTransitionDone ? 'done' : 'moving'}:${_value ?? '-'}',
      textDirection: TextDirection.ltr,
    );
  }
}

void main() {
  testWidgets('a page without an opening animation is done immediately', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _Probe(data: Future.value('x'))));
    await tester.pump();

    expect(find.text('done:x'), findsOneWidget);
  });

  testWidgets('results that arrive mid-transition are shown after it ends', (
    tester,
  ) async {
    final data = Completer<String>();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => _Probe(data: data.future)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    data.complete('x');
    await tester.pump(const Duration(milliseconds: 50));
    // API ตอบแล้ว แต่ยังเลื่อนหน้าอยู่ ยังไม่วาดผล
    expect(find.text('moving:-'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('done:x'), findsOneWidget);
  });

  testWidgets('results that arrive after the transition are shown at once', (
    tester,
  ) async {
    final data = Completer<String>();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => _Probe(data: data.future)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('done:-'), findsOneWidget);

    data.complete('x');
    // ไม่เลื่อนเวลาเลย: แค่ให้ microtask กับเฟรมถัดไปทำงาน
    await tester.pump();
    await tester.pump();
    expect(find.text('done:x'), findsOneWidget);
  });
}
