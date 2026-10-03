import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/views/pages/create_section_steps_page.dart';
import 'package:flutter_application_1/widgets/cooking_steps/section_editor_card.dart';

class CreateCookingStepsPage extends StatefulWidget {
  const CreateCookingStepsPage({
    super.key,
    this.initialDraft,
  });

  final RecipeSectionDraft? initialDraft;

  @override
  State<CreateCookingStepsPage> createState() =>
      _CreateCookingStepsPageState();
}

class _CreateCookingStepsPageState extends State<CreateCookingStepsPage> {
  final _formKey = GlobalKey<FormState>();

  late final List<SectionEditor> _sections;

  @override
  void initState() {
    super.initState();

    final draft = widget.initialDraft;

    _sections =
        draft?.sections.map(SectionEditor.fromDraft).toList() ?? [];
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }

    super.dispose();
  }

  RecipeSectionDraft? _collectDraft() {
    if (_sections.isEmpty) return null;

    return RecipeSectionDraft(
      sections: _sections.map((section) => section.toDraft()).toList(),
    );
  }

  void _autoSaveAndPop() {
    Navigator.of(context).pop(_collectDraft());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
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
            .fold<int>(
              0,
              (total, item) => total + item.contents.length,
            ) +
        1;

    final contents =
        await Navigator.of(context).push<List<RecipeContentDraft>>(
      MaterialPageRoute<List<RecipeContentDraft>>(
        builder: (_) => CreateSectionStepsPage(
          sectionTitle: sectionTitle,
          firstStepNumber: firstStepNumber,
          initialContents: section.contents,
        ),
      ),
    );

    if (!mounted || contents == null) return;

    setState(() {
      section.contents = contents;
      section.isExpanded = true;
    });
  }

  int _getFirstStepNumber(int index) {
    return _sections
            .take(index)
            .fold<int>(
              0,
              (total, item) => total + item.contents.length,
            ) +
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
        backgroundColor: const Color(0xFFF6F5F0),
        appBar: AppBar(
          title: const Text('ขั้นตอนการทำอาหาร'),
          backgroundColor: const Color(0xFFF6F5F0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'กลับ (บันทึกอัตโนมัติ)',
            onPressed: _autoSaveAndPop,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            children: [
              for (var index = 0; index < _sections.length; index++)
                SectionEditorCard(
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
                  titleValidator: (value) =>
                      _required(value, 'หัวข้อขั้นตอน'),
                ),

              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มหัวข้อขั้นตอน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}