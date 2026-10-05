import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/content/app_texts.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_application_1/views/pages/text_sections_page.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RegisterTerms extends StatefulWidget {
  const RegisterTerms({
    required this.accepted,
    required this.onChanged,
    super.key,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  State<RegisterTerms> createState() => _RegisterTermsState();
}

class _RegisterTermsState extends State<RegisterTerms> {
  static const _linkStyle = AuthStyle.linkStyle;

  // TapGestureRecognizer ต้อง dispose เอง เลยต้องเป็น StatefulWidget
  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = () =>
        _openSections(context.l10n.termsOfUse, termsSections(context.l10n));
  late final _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => _openSections(
      context.l10n.privacyPolicy,
      privacySections(context.l10n),
    );

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _openSections(String title, List<TextSection> sections) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TextSectionsPage(title: title, sections: sections),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.accepted,
          activeColor: AuthStyle.primary,
          visualDensity: VisualDensity.compact,
          onChanged: (value) => widget.onChanged(value ?? false),
        ),
        Expanded(
          // แตะตัวหนังสือธรรมดาก็ติ๊กได้ ส่วนลิงก์สีแดงจะเปิดหน้าเนื้อหาแทน
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onChanged(!widget.accepted),
            child: Padding(
              padding: const EdgeInsets.only(top: 7, left: 6),
              child: Text.rich(
                TextSpan(
                  text: context.l10n.termsAgreePrefix,
                  children: [
                    TextSpan(
                      text: context.l10n.termsAgreeUserAgreement,
                      style: _linkStyle,
                      recognizer: _termsRecognizer,
                    ),
                    TextSpan(text: context.l10n.termsAgreeAnd),
                    TextSpan(
                      text: context.l10n.termsAgreePrivacy,
                      style: _linkStyle,
                      recognizer: _privacyRecognizer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
