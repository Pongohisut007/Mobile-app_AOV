import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/views/pages/create_section_steps_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/cooking_steps/section_editor_card.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

class CreateCookingStepsPage extends StatefulWidget {
  const CreateCookingStepsPage({super.key, this.initialDraft});

  final RecipeSectionDraft? initialDraft;

  @override
  State<CreateCookingStepsPage> createState() => _CreateCookingStepsPageState();
}

class _CreateCookingStepsPageState extends State<CreateCookingStepsPage> {
  final _formKey = GlobalKey<FormState>();

  late final List<SectionEditor> _sections;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();

    final draft = widget.initialDraft;

    _sections = draft?.sections.map(SectionEditor.fromDraft).toList() ?? [];
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }

    super.dispose();
  }

  // คืนค่าเสมอ (แม้ไม่มี section) เพื่อให้หน้าก่อนหน้ารู้ว่าผู้ใช้ลบหมดแล้ว
  // ตัด section ที่ว่างทั้งหัวข้อและขั้นตอนทิ้ง จะได้ไม่ถูกนับจำนวน
  RecipeSectionDraft _collectDraft() {
    return RecipeSectionDraft(
      sections: _sections
          .map((section) => section.toDraft())
          .where(
            (section) =>
                section.title.isNotEmpty || section.contents.isNotEmpty,
          )
          .toList(),
    );
  }

  void _autoSaveAndPop() {
    // กันกดย้อนกลับซ้ำระหว่าง animation ซึ่งจะไป pop หน้าก่อนหน้าด้วย
    if (_isPopping) return;
    _isPopping = true;
    Navigator.of(context).pop(_collectDraft());
  }

  // ใช้เตือนว่ายังกรอกไม่ครบ
  void _showMessage(String message) {
    showAppSnackBar(context, message, type: AppSnackType.error);
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'กรอก$label';
    }

    return null;
  }

  Future<void> _openSection(SectionEditor section) async {
    final sectionTitle = section.title.text.trim();

    if (sectionTitle.isEmpty) {
      _showMessage('กรอกหัวข้อขั้นตอนก่อนเพิ่มขั้นตอน');
      return;
    }

    final sectionIndex = _sections.indexOf(section);

    final firstStepNumber =
        _sections
            .take(sectionIndex)
            .fold<int>(0, (total, item) => total + item.contents.length) +
        1;

    final contents = await Navigator.of(context).push<List<RecipeContentDraft>>(
      MaterialPageRoute<List<RecipeContentDraft>>(
        builder: (_) => CreateSectionStepsPage(
          sectionTitle: sectionTitle,
          firstStepNumber: firstStepNumber,
          initialContents: section.contents,
        ),
      ),
    );

    if (!mounted || _isPopping || contents == null) return;

    setState(() {
      section.contents = contents;
      section.isExpanded = true;
    });
  }

  int _getFirstStepNumber(int index) {
    return _sections
            .take(index)
            .fold<int>(0, (total, item) => total + item.contents.length) +
        1;
  }

  void _addSection() {
    setState(() {
      _sections.add(SectionEditor());
    });
  }

  void _deleteSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        _autoSaveAndPop();
      },
      child: Scaffold(
        backgroundColor: RecipeFormStyle.background,
        appBar: RecipeFormStyle.appBar(
          title: 'ขั้นตอนการทำอาหาร',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'กลับ (บันทึกอัตโนมัติ)',
            onPressed: _autoSaveAndPop,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const _IntroBanner(),

              if (_sections.isEmpty) const _EmptySections(),

              for (var index = 0; index < _sections.length; index++)
                SectionEditorCard(
                  key: ObjectKey(_sections[index]),
                  section: _sections[index],
                  index: index,
                  firstStepNumber: _getFirstStepNumber(index),
                  onTap: () => _openSection(_sections[index]),
                  onToggleExpanded: () {
                    setState(() {
                      _sections[index].isExpanded =
                          !_sections[index].isExpanded;
                    });
                  },
                  onDelete: () => _deleteSection(index),
                  onTitleChanged: (_) {
                    setState(() {});
                  },
                  titleValidator: (value) => _required(value, 'หัวข้อขั้นตอน'),
                ),

              RecipeAddButton(
                label: 'เพิ่มหัวข้อขั้นตอน',
                onPressed: _addSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// คำอธิบายสั้น ๆ ด้านบน: แบ่งขั้นตอนเป็นชุด และย้อนกลับได้โดยไม่ต้องกดบันทึก
class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RecipeFormStyle.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: RecipeFormStyle.accent,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'แบ่งขั้นตอนเป็นชุด เช่น "เตรียมวัตถุดิบ" "ปรุง" "จัดเสิร์ฟ" '
              'แล้วแตะการ์ดเพื่อเพิ่มขั้นตอนย่อย กดย้อนกลับได้เลย ระบบบันทึกให้อัตโนมัติ',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.format_list_numbered_rounded,
            size: 48,
            color: RecipeFormStyle.muted,
          ),
          SizedBox(height: 12),
          Text(
            'ยังไม่มีหัวข้อขั้นตอน',
            style: TextStyle(
              color: RecipeFormStyle.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'เริ่มจากเพิ่มหัวข้อชุดแรกด้านล่าง',
            style: TextStyle(color: RecipeFormStyle.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
