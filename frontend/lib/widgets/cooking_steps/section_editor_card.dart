import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/models/recipe_section_draft.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

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
    final stepCount = section.contents.length;

    return Container(
      key: ObjectKey(section),
      margin: const EdgeInsets.only(bottom: 14),
      child: ShadowBox(
        borderRadius: BorderRadius.circular(RecipeFormStyle.cardRadius),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RecipeFormStyle.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวการ์ด: ป้ายลำดับชุด + จำนวนขั้นตอน + ปุ่มพับ/ลบ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: const ShapeDecoration(
                          color: RecipeFormStyle.ink,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          'ชุดที่ ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$stepCount ขั้นตอน',
                        style: const TextStyle(
                          color: RecipeFormStyle.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onToggleExpanded,
                        visualDensity: VisualDensity.compact,
                        color: RecipeFormStyle.muted,
                        tooltip: section.isExpanded
                            ? 'พับขั้นตอน'
                            : 'แสดงขั้นตอน',
                        icon: Icon(
                          section.isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        color: RecipeFormStyle.muted,
                        tooltip: 'ลบหัวข้อขั้นตอน',
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextFormField(
                      controller: section.title,
                      decoration: RecipeFormStyle.input(
                        hint: 'หัวข้อขั้นตอน',
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: RecipeFormStyle.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      validator: titleValidator,
                      onChanged: onTitleChanged,
                    ),
                  ),

                  if (section.isExpanded && section.contents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 14, 8, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 18,
                            color: RecipeFormStyle.muted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม',
                              style: TextStyle(
                                color: RecipeFormStyle.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (section.isExpanded && section.contents.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (
                      var stepIndex = 0;
                      stepIndex < section.contents.length;
                      stepIndex++
                    )
                      _StepRow(
                        number: firstStepNumber + stepIndex,
                        title: section.contents[stepIndex].title,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// แถวสรุปขั้นตอนย่อยในการ์ด: เลขขั้นตอนในวงกลม + ชื่อ
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: RecipeFormStyle.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: RecipeFormStyle.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: RecipeFormStyle.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ขั้นตอนที่ $number',
              style: const TextStyle(
                color: RecipeFormStyle.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isEmpty ? 'ยังไม่มีชื่อขั้นตอนย่อย' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: title.isEmpty
                      ? RecipeFormStyle.muted
                      : RecipeFormStyle.ink,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: RecipeFormStyle.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionEditor {
  SectionEditor({String title = '', List<RecipeContentDraft>? contents})
    : title = TextEditingController(text: title),
      contents = contents ?? [],
      isExpanded = true;

  factory SectionEditor.fromDraft(RecipeSectionGroupDraft draft) {
    return SectionEditor(title: draft.title, contents: draft.contents);
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
