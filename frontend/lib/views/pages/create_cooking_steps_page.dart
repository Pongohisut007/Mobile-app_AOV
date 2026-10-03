import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/views/pages/create_section_steps_page.dart';

class CreateCookingStepsPage extends StatefulWidget {
  const CreateCookingStepsPage({super.key, this.initialDraft});

  final RecipeSectionDraft? initialDraft;

  @override
  State<CreateCookingStepsPage> createState() => _CreateCookingStepsPageState();
}

class _CreateCookingStepsPageState extends State<CreateCookingStepsPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_SectionEditor> _sections;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _sections = draft?.sections.map(_SectionEditor.fromDraft).toList() ?? [];
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  /// Collect current data as a draft without validation.
  /// Returns null only when there are no sections at all.
  RecipeSectionDraft? _collectDraft() {
    if (_sections.isEmpty) return null;
    return RecipeSectionDraft(
      sections: _sections.map((section) => section.toDraft()).toList(),
    );
  }

  /// Auto-save: pop the current draft back to the parent page.
  void _autoSaveAndPop() {
    Navigator.of(context).pop(_collectDraft());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'กรอก$label';
    return null;
  }

  Future<void> _openSection(_SectionEditor section) async {
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
    if (!mounted || contents == null) return;
    setState(() {
      section.contents = contents;
      section.isExpanded = true;
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              for (var index = 0; index < _sections.length; index++)
                _buildSectionCard(index),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _sections.add(_SectionEditor())),
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

  Widget _buildSectionCard(int index) {
    final section = _sections[index];
    final firstStepNumber =
        _sections
            .take(index)
            .fold<int>(0, (total, item) => total + item.contents.length) +
        1;
    return Container(
      key: ObjectKey(section),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E2DA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSection(section),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: section.title,
                        decoration: const InputDecoration(
                          hintText: 'หัวข้อขั้นตอน',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) =>
                            _required(value, 'หัวข้อขั้นตอน'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => section.isExpanded = !section.isExpanded,
                      ),
                      tooltip: section.isExpanded
                          ? 'พับขั้นตอน'
                          : 'แสดงขั้นตอน',
                      icon: Icon(
                        section.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        section.dispose();
                        _sections.removeAt(index);
                      }),
                      tooltip: 'ลบหัวข้อขั้นตอน',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                if (section.isExpanded && section.contents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('ยังไม่มีขั้นตอน แตะการ์ดเพื่อเพิ่ม'),
                  ),
                if (section.isExpanded)
                  for (
                    var stepIndex = 0;
                    stepIndex < section.contents.length;
                    stepIndex++
                  ) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'ขั้นตอนที่ ${firstStepNumber + stepIndex}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.contents[stepIndex].title.isEmpty
                                ? 'ยังไม่มีชื่อหัวข้อขั้นตอน'
                                : section.contents[stepIndex].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionEditor {
  _SectionEditor({String title = '', List<RecipeContentDraft>? contents})
    : title = TextEditingController(text: title),
      contents = contents ?? [],
      isExpanded = true;

  factory _SectionEditor.fromDraft(RecipeSectionGroupDraft draft) {
    return _SectionEditor(title: draft.title, contents: draft.contents);
  }

  final TextEditingController title;
  List<RecipeContentDraft> contents;
  bool isExpanded;

  RecipeSectionGroupDraft toDraft() {
    return RecipeSectionGroupDraft(
      title: title.text.trim(),
      contents: contents,
    );
  }

  void dispose() {
    title.dispose();
  }
}
