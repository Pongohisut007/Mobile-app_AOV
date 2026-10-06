import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/app_sheet.dart';

/// bottom sheet เลือกภาษา ใช้ทั้งหน้าตั้งค่าและหน้า login/register
/// เลือกแล้วทั้งแอปเปลี่ยนภาษาทันที (AppLanguage จำไว้ในเครื่อง)
Future<void> showLanguagePicker(BuildContext context) async {
  final selected = await showAppBottomSheet<Locale>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(title: sheetContext.l10n.chooseLanguage),
          for (final locale in AppLanguage.supported)
            AppSheetOption(
              icon: Icons.translate_rounded,
              title: AppLanguage.nativeName(locale),
              selectable: true,
              selected: locale == AppLanguage.current,
              onTap: () => Navigator.pop(sheetContext, locale),
            ),
        ],
      ),
    ),
  );
  if (selected == null || selected == AppLanguage.current) return;
  await AppLanguage.change(selected);
}
