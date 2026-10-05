import 'package:flutter_application_1/l10n/l10n.dart';

/// ข้อความในหน้าช่วยเหลือและติดต่อ / นโยบายความเป็นส่วนตัว / ข้อกำหนดการใช้งาน
/// เนื้อหาอยู่ใน lib/l10n/app_*.arb (คีย์ faq* / privacy* / terms*)
/// เขียนจากสิ่งที่แอปทำจริงในตอนนี้ ถ้าระบบเปลี่ยน (เช่น เพิ่มการชำระเงินจริง
/// หรือระบบรีเซ็ตรหัสผ่าน) ต้องกลับมาแก้ข้อความใน ARB ด้วย
///
/// นโยบาย/ข้อกำหนดเป็นฉบับร่าง ควรให้ผู้รับผิดชอบด้านกฎหมายตรวจก่อนปล่อยแอปจริง
class TextSection {
  const TextSection(this.title, this.body);

  final String title;
  final String body;
}

List<TextSection> faqSections(AppLocalizations l10n) => [
  TextSection(l10n.faqCreateTitle, l10n.faqCreateBody),
  TextSection(l10n.faqDraftTitle, l10n.faqDraftBody),
  TextSection(l10n.faqEditTitle, l10n.faqEditBody),
  TextSection(l10n.faqBuyTitle, l10n.faqBuyBody),
  TextSection(l10n.faqAiTitle, l10n.faqAiBody),
  TextSection(l10n.faqRateTitle, l10n.faqRateBody),
  TextSection(l10n.faqProfileTitle, l10n.faqProfileBody),
  TextSection(l10n.faqForgotTitle, l10n.faqForgotBody),
  TextSection(l10n.faqLostTitle, l10n.faqLostBody),
];

List<TextSection> privacySections(AppLocalizations l10n) => [
  TextSection(l10n.privacyCollectTitle, l10n.privacyCollectBody),
  TextSection(l10n.privacyVisibleTitle, l10n.privacyVisibleBody),
  TextSection(l10n.privacyAiTitle, l10n.privacyAiBody),
  TextSection(l10n.privacyDeviceTitle, l10n.privacyDeviceBody),
  TextSection(l10n.privacyDeleteTitle, l10n.privacyDeleteBody),
  TextSection(l10n.privacyContactTitle, l10n.privacyContactBody),
];

List<TextSection> termsSections(AppLocalizations l10n) => [
  TextSection(l10n.termsAccountTitle, l10n.termsAccountBody),
  TextSection(l10n.termsContentTitle, l10n.termsContentBody),
  TextSection(l10n.termsPurchaseTitle, l10n.termsPurchaseBody),
  TextSection(l10n.termsAiTitle, l10n.termsAiBody),
  TextSection(l10n.termsCloseTitle, l10n.termsCloseBody),
  TextSection(l10n.termsChangesTitle, l10n.termsChangesBody),
];
