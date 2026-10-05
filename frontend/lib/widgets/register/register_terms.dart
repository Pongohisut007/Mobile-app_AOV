import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/content/app_texts.dart';
import 'package:flutter_application_1/views/pages/text_sections_page.dart';

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
  static const _linkStyle = TextStyle(
    color: Color(0xFFF20D13),
    fontWeight: FontWeight.w700,
  );

  // TapGestureRecognizer ต้อง dispose เอง เลยต้องเป็น StatefulWidget
  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => _openSections('ข้อกำหนดการใช้งาน', termsSections);
  late final _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => _openSections('นโยบายความเป็นส่วนตัว', privacySections);

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
          activeColor: const Color(0xFFF20D13),
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
                  text: 'I agree with the ',
                  children: [
                    TextSpan(
                      text: 'User Agreement',
                      style: _linkStyle,
                      recognizer: _termsRecognizer,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
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
