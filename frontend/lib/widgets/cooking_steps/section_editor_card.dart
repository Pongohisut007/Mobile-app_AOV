import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';

class SectionEditorCard extends StatelessWidget {
  const SectionEditorCard({
    super.key,
    required this.section,
    required this.index,
    required this.firstStepNumber,
    required this.onTap,
    required this.onToggleExpanded,
    required this.onDelete,
    required this.onTitleChanged,
    required this.titleValidator,
  });

  final SectionEditor section;
  final int index;
  final int firstStepNumber;

  final VoidCallback onTap;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDelete;
  final ValueChanged<String> onTitleChanged;
  final FormFieldValidator<String> titleValidator;

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
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
                        validator: titleValidator,
                        onChanged: onTitleChanged,
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleExpanded,
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
                      onPressed: onDelete,
                      tooltip: 'ลบหัวข้อขั้นตอน',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),

                if (section.isExpanded && section.contents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม'),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.contents[stepIndex].title.isEmpty
                                ? 'ยังไม่มีชื่อขั้นตอนย่อย'
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

class SectionEditor {
  SectionEditor({
    String title = '',
    List<RecipeContentDraft>? contents,
  })  : title = TextEditingController(text: title),
        contents = contents ?? [],
        isExpanded = true;

  factory SectionEditor.fromDraft(RecipeSectionGroupDraft draft) {
    return SectionEditor(
      title: draft.title,
      contents: draft.contents,
    );
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
