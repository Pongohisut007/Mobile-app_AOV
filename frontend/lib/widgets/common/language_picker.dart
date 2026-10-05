import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// bottom sheet เลือกภาษา ใช้ทั้งหน้าตั้งค่าและหน้า login/register
/// เลือกแล้วทั้งแอปเปลี่ยนภาษาทันที (AppLanguage จำไว้ในเครื่อง)
Future<void> showLanguagePicker(BuildContext context) async {
  final selected = await showModalBottomSheet<Locale>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              sheetContext.l10n.chooseLanguage,
              style: const TextStyle(
                color: ProfileColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final locale in AppLanguage.supported)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(AppLanguage.nativeName(locale)),
              trailing: locale == AppLanguage.current
                  ? const Icon(Icons.check_rounded, color: ProfileColors.ink)
                  : null,
              onTap: () => Navigator.pop(sheetContext, locale),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (selected == null || selected == AppLanguage.current) return;
  await AppLanguage.change(selected);
}
