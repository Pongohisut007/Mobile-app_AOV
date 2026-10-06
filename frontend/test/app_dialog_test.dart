import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

Future<T?> _open<T>(
  WidgetTester tester,
  Future<T> Function(BuildContext context) show,
) async {
  T? result;
  var done = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await show(context);
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  addTearDown(() => expect(done, isTrue));
  return result;
}

void main() {
  Future<bool> confirm(BuildContext context) => showAppConfirmDialog(
    context,
    icon: Icons.delete_outline_rounded,
    title: 'Delete?',
    message: 'Cannot undo',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    danger: true,
  );

  testWidgets('confirm returns true only when confirmed', (tester) async {
    await _open(tester, confirm);
    expect(find.text('Delete?'), findsOneWidget);
    expect(find.text('Cannot undo'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), AppDialogColors.danger);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);
  });

  testWidgets('confirm returns the tapped value', (tester) async {
    late Future<bool> pending;
    await _open(tester, (context) => pending = confirm(context));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
  });

  testWidgets('cancel and tapping outside both return false', (tester) async {
    late Future<bool> pending;
    await _open(tester, (context) => pending = confirm(context));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await pending, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);
    expect(await pending, isFalse);
  });

  testWidgets('showAppDialog returns the value of the tapped action', (
    tester,
  ) async {
    late Future<String?> pending;
    await _open(
      tester,
      (context) => pending = showAppDialog<String?>(
        context,
        icon: Icons.edit_note_rounded,
        title: 'Leave?',
        actions: const [
          AppDialogAction(label: 'Save', value: 'save'),
          AppDialogAction(
            label: 'Discard',
            value: 'discard',
            style: AppDialogActionStyle.secondary,
            danger: true,
          ),
          AppDialogAction(
            label: 'Stay',
            value: null,
            style: AppDialogActionStyle.text,
          ),
        ],
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await pending, 'discard');
  });
}
