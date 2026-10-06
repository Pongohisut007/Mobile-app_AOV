import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/recipe_ingredient.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/common/app_sheet.dart';

/// การ์ด "วัตถุดิบ" ในหน้าสร้าง/แก้สูตร: รายการ + เพิ่ม/แก้/ลบ/เลื่อนลำดับ
class RecipeIngredientsSection extends StatelessWidget {
  const RecipeIngredientsSection({
    super.key,
    required this.ingredients,
    required this.catalog,
    required this.onChanged,
    this.enabled = true,
  });

  final List<RecipeIngredientLine> ingredients;

  /// คลังวัตถุดิบไว้ให้เลือก (ว่างได้ ยังพิมพ์ชื่อใหม่เองได้)
  final List<IngredientOption> catalog;
  final ValueChanged<List<RecipeIngredientLine>> onChanged;
  final bool enabled;

  Future<void> _edit(BuildContext context, {int? index}) async {
    final edited = await showIngredientEditor(
      context,
      catalog: catalog,
      initial: index == null ? null : ingredients[index],
      others: [
        for (var i = 0; i < ingredients.length; i++)
          if (i != index) ingredients[i],
      ],
    );
    if (edited == null) return;
    final next = [...ingredients];
    if (index == null) {
      next.add(edited);
    } else {
      next[index] = edited;
    }
    onChanged(next);
  }

  void _move(int index, int offset) {
    final next = [...ingredients];
    final item = next.removeAt(index);
    next.insert(index + offset, item);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecipeFormSectionHeading(
            title: context.l10n.ingredients,
            subtitle: ingredients.isEmpty
                ? context.l10n.ingredientsEmptyHint
                : context.l10n.itemCount(ingredients.length),
            icon: Icons.shopping_basket_rounded,
          ),
          const SizedBox(height: 14),
          for (final (index, item) in ingredients.indexed)
            _IngredientRow(
              key: ValueKey('ingredient-$index-${item.name}'),
              item: item,
              onTap: enabled ? () => _edit(context, index: index) : null,
              onRemove: enabled
                  ? () => onChanged([...ingredients]..removeAt(index))
                  : null,
              onMoveUp: enabled && index > 0 ? () => _move(index, -1) : null,
              onMoveDown: enabled && index < ingredients.length - 1
                  ? () => _move(index, 1)
                  : null,
            ),
          const SizedBox(height: 6),
          RecipeAddButton(
            label: context.l10n.addIngredient,
            onPressed: enabled ? () => _edit(context) : null,
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    super.key,
    required this.item,
    this.onTap,
    this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final RecipeIngredientLine item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (item.amountLabel.isNotEmpty) item.amountLabel,
      if (item.note != null) item.note!,
      if (item.isOptional) context.l10n.ingredientOptional,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: RecipeFormStyle.fieldFill,
        borderRadius: BorderRadius.circular(RecipeFormStyle.fieldRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RecipeFormStyle.fieldRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: RecipeFormStyle.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: const TextStyle(
                            color: RecipeFormStyle.muted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: WidgetsLocalizations.of(context).reorderItemUp,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  tooltip: WidgetsLocalizations.of(context).reorderItemDown,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                IconButton(
                  tooltip: context.l10n.remove,
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// หน่วยที่ใช้บ่อย แตะเพื่อใส่ (พิมพ์หน่วยอื่นเองก็ได้)
const _commonUnits = [
  'กรัม',
  'กิโลกรัม',
  'มล.',
  'ลิตร',
  'ช้อนโต๊ะ',
  'ช้อนชา',
  'ถ้วย',
  'ฟอง',
  'ลูก',
  'กลีบ',
  'ต้น',
  'ใบ',
];

/// ชีตเพิ่ม/แก้วัตถุดิบ คืน null ถ้ายกเลิก
/// [others] = วัตถุดิบอื่นในสูตร (กันใส่ซ้ำ)
Future<RecipeIngredientLine?> showIngredientEditor(
  BuildContext context, {
  required List<IngredientOption> catalog,
  required List<RecipeIngredientLine> others,
  RecipeIngredientLine? initial,
}) {
  return showAppBottomSheet<RecipeIngredientLine>(
    context,
    isScrollControlled: true,
    builder: (_) =>
        _IngredientEditor(catalog: catalog, others: others, initial: initial),
  );
}

class _IngredientEditor extends StatefulWidget {
  const _IngredientEditor({
    required this.catalog,
    required this.others,
    this.initial,
  });

  final List<IngredientOption> catalog;
  final List<RecipeIngredientLine> others;
  final RecipeIngredientLine? initial;

  @override
  State<_IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<_IngredientEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.initial?.amount == null
        ? ''
        : RecipeIngredientLine(
            name: '',
            amount: widget.initial!.amount,
          ).amountLabel,
  );
  late final _unitController = TextEditingController(
    text: widget.initial?.unit ?? '',
  );
  late final _noteController = TextEditingController(
    text: widget.initial?.note ?? '',
  );
  late String _name = widget.initial?.name ?? '';

  /// เลือกจากคลัง = id ของตัวนั้น พิมพ์เองแล้วไม่ตรงกับในคลัง = null
  late String? _ingredientId = widget.initial?.ingredientId;
  late bool _isOptional = widget.initial?.isOptional ?? false;

  @override
  void dispose() {
    _amountController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IngredientOption? _catalogMatch(String name) {
    final key = RecipeIngredientLine.normalizeName(name).toLowerCase();
    for (final option in widget.catalog) {
      if (RecipeIngredientLine.normalizeName(option.name).toLowerCase() ==
          key) {
        return option;
      }
    }
    return null;
  }

  void _onNameChanged(String value) {
    setState(() {
      _name = value;
      // พิมพ์ตรงกับในคลังพอดี ถือว่าเลือกตัวนั้น
      _ingredientId = _catalogMatch(value)?.id;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amountText = _amountController.text.trim();
    Navigator.of(context).pop(
      RecipeIngredientLine(
        ingredientId: _ingredientId,
        name: RecipeIngredientLine.normalizeName(_name),
        amount: amountText.isEmpty ? null : double.parse(amountText),
        unit: _optional(_unitController.text),
        note: _optional(_noteController.text),
        isOptional: _isOptional,
      ),
    );
  }

  static String? _optional(String value) =>
      value.trim().isEmpty ? null : value.trim();

  String? _validateName(BuildContext context, String? value) {
    final name = RecipeIngredientLine.normalizeName(value ?? '');
    if (name.isEmpty) return context.l10n.ingredientNameRequired;
    if (name.length > 150) return context.l10n.ingredientNameRequired;
    final candidate = RecipeIngredientLine(
      ingredientId: _ingredientId,
      name: name,
    );
    if (widget.others.any(candidate.sameIngredientAs)) {
      return context.l10n.ingredientDuplicate;
    }
    return null;
  }

  String? _validateAmount(BuildContext context, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    // ตรงกับที่ backend รับ: ไม่ติดลบ ทศนิยมไม่เกิน 3 ตำแหน่ง
    if (!RegExp(r'^\d{1,7}(\.\d{1,3})?$').hasMatch(text)) {
      return context.l10n.ingredientAmountInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _name.trim().isNotEmpty && _ingredientId == null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial == null
                    ? context.l10n.addIngredient
                    : context.l10n.editIngredient,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: RecipeFormStyle.ink,
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<IngredientOption>(
                initialValue: TextEditingValue(text: _name),
                displayStringForOption: (option) => option.name,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return const Iterable.empty();
                  return widget.catalog
                      .where(
                        (option) => option.name.toLowerCase().contains(query),
                      )
                      .take(8);
                },
                onSelected: (option) => setState(() {
                  _name = option.name;
                  _ingredientId = option.id;
                }),
                fieldViewBuilder: (context, controller, focusNode, _) =>
                    TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: widget.initial == null,
                      textInputAction: TextInputAction.next,
                      maxLength: 150,
                      onChanged: _onNameChanged,
                      validator: (value) => _validateName(context, value),
                      decoration:
                          RecipeFormStyle.input(
                            label: context.l10n.ingredientName,
                            hint: context.l10n.ingredientNameHint,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: RecipeFormStyle.muted,
                            ),
                          ).copyWith(
                            counterText: '',
                            helperText: isNew
                                ? context.l10n.ingredientIsNew
                                : null,
                          ),
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateAmount(context, value),
                      decoration: RecipeFormStyle.input(
                        label: context.l10n.ingredientAmount,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      maxLength: 50,
                      textInputAction: TextInputAction.next,
                      decoration: RecipeFormStyle.input(
                        label: context.l10n.ingredientUnit,
                      ).copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final unit in _commonUnits)
                    ActionChip(
                      label: Text(unit),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _unitController.text = unit;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLength: 255,
                textInputAction: TextInputAction.done,
                decoration: RecipeFormStyle.input(
                  label: context.l10n.ingredientNote,
                ).copyWith(counterText: ''),
              ),
              CheckboxListTile(
                value: _isOptional,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(context.l10n.ingredientOptional),
                onChanged: (value) =>
                    setState(() => _isOptional = value ?? false),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _submit,
                style: RecipeFormStyle.primaryButton(),
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
