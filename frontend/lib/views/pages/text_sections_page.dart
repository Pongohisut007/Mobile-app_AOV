import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/app_info.dart';
import 'package:flutter_application_1/content/app_texts.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// หน้าข้อความยาว (นโยบายความเป็นส่วนตัว / ข้อกำหนดการใช้งาน)
class TextSectionsPage extends StatelessWidget {
  const TextSectionsPage({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<TextSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: RecipeFormStyle.appBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RecipeFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, section) in sections.indexed) ...[
                  if (index > 0) const SizedBox(height: 18),
                  Text(
                    section.title,
                    style: const TextStyle(
                      color: ProfileColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.body,
                    style: const TextStyle(
                      color: ProfileColors.ink,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Help & support: คำถามที่พบบ่อย (แตะเพื่อเปิดคำตอบ) + ช่องทางติดต่อ
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: RecipeFormStyle.appBar(title: 'Help & support'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 4, 6, 10),
            child: Text(
              'คำถามที่พบบ่อย',
              style: TextStyle(
                color: ProfileColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, section) in faqSections.indexed) ...[
                  if (index > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  Theme(
                    // เอาเส้นขอบของ ExpansionTile ออก ให้กลืนกับการ์ด
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      iconColor: ProfileColors.ink,
                      collapsedIconColor: ProfileColors.muted,
                      expandedAlignment: Alignment.centerLeft,
                      title: Text(
                        section.title,
                        style: const TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      children: [
                        Text(
                          section.body,
                          style: const TextStyle(
                            color: ProfileColors.ink,
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ยังไม่ได้ตั้งอีเมลทีมงาน = ไม่แสดงช่องทางติดต่อ
          if (AppInfo.supportEmail.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _ContactCard(email: AppInfo.supportEmail),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 64,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(
          Icons.mail_outline_rounded,
          color: ProfileColors.ink,
        ),
        title: const Text(
          'ติดต่อทีมงาน',
          style: TextStyle(
            color: ProfileColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(email),
        trailing: const Icon(Icons.copy_rounded, color: ProfileColors.muted),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: email));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('คัดลอกอีเมลแล้ว')));
        },
      ),
    );
  }
}
