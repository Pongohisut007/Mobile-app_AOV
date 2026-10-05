import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'package:flutter_application_1/l10n/app_localizations.dart';

/// ภาษาของแอป: ไทยเป็นภาษาหลัก มีอังกฤษเป็นภาษาที่สอง
/// ข้อความทั้งหมดอยู่ใน lib/l10n/app_th.arb (ต้นฉบับ) และ app_en.arb
/// ผู้ใช้เลือกภาษาได้ที่หน้าตั้งค่า เลือกแล้วจำไว้ในเครื่อง (ออกจากระบบก็ไม่หาย)
abstract final class AppLanguage {
  static const thai = Locale('th');
  static const english = Locale('en');

  /// ภาษาที่เลือกได้ เรียงตามที่แสดงในหน้าตั้งค่า
  static const supported = [thai, english];

  static const _storageKey = 'app_language';
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// MaterialApp ฟังตัวนี้ เปลี่ยนค่าแล้วทั้งแอปเปลี่ยนภาษาทันที
  static final ValueNotifier<Locale> notifier = ValueNotifier(thai);

  /// ภาษาที่แอปใช้อยู่
  static Locale get current => notifier.value;

  /// ชื่อภาษาเขียนด้วยภาษานั้นเอง (คนที่อ่านอีกภาษาไม่ออกจะได้หาเจอ)
  static String nativeName(Locale locale) => switch (locale.languageCode) {
    'en' => 'English',
    _ => 'ไทย',
  };

  /// อ่านภาษาที่เคยเลือกไว้ เรียกก่อน runApp
  /// อ่านไม่ได้หรือไม่เคยเลือก = ใช้ภาษาไทย
  static Future<void> load({FlutterSecureStorage? storage}) async {
    if (storage != null) _storage = storage;
    try {
      final code = await _storage.read(key: _storageKey);
      notifier.value = _fromCode(code);
    } catch (_) {
      notifier.value = thai;
    }
  }

  /// เปลี่ยนภาษาทั้งแอปทันที แล้วจำไว้ใช้ครั้งหน้า
  static Future<void> change(Locale locale) async {
    final selected = _fromCode(locale.languageCode);
    notifier.value = selected;
    try {
      await _storage.write(key: _storageKey, value: selected.languageCode);
    } catch (_) {
      // จำไม่ได้ก็ยังใช้ภาษาที่เลือกได้จนกว่าจะปิดแอป
    }
  }

  static Locale _fromCode(String? code) => supported.firstWhere(
    (locale) => locale.languageCode == code,
    orElse: () => thai,
  );
}

extension AppLocalizationsContext on BuildContext {
  /// ข้อความตามภาษาปัจจุบัน ใช้ใน widget: `context.l10n.save`
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// ข้อความตามภาษาปัจจุบัน สำหรับที่ไม่มี BuildContext (repository / bloc)
AppLocalizations get appL10n => lookupAppLocalizations(AppLanguage.current);

/// ข้อความที่ประกอบจากค่าในข้อมูล ใช้ซ้ำหลายหน้า
extension AppLocalizationsFormat on AppLocalizations {
  /// ระดับความยากจาก API ('easy' / 'medium' / 'hard')
  String difficultyLabel(String? value) => switch (value) {
    'easy' => difficultyEasy,
    'medium' => difficultyMedium,
    'hard' => difficultyHard,
    null || '' => '-',
    _ => value,
  };

  /// ราคา 0 = "ฟรี" นอกนั้นเป็นบาทไม่มีทศนิยม
  String priceLabel(double price) =>
      price == 0 ? priceFree : '฿${price.toStringAsFixed(0)}';
}
