import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// MaterialApp ที่ตั้งภาษาเหมือนแอปจริง (ไทยเป็นภาษาหลัก)
/// หน้าที่ใช้ context.l10n ต้องมี delegate ของ AppLocalizations ไม่งั้น build ไม่ได้
MaterialApp localizedApp({required Widget home, Locale? locale}) {
  return MaterialApp(
    locale: locale ?? AppLanguage.current,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}
