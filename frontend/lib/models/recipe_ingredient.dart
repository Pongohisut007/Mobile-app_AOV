/// วัตถุดิบหนึ่งรายการของสูตร
///
/// [ingredientId] = เลือกจากคลัง ถ้าเป็น null คือพิมพ์ชื่อใหม่ (backend เพิ่มเข้าคลังให้)
/// [amount]/[unit]/[note] เป็น null ได้ เช่น "เกลือ (ปริมาณตามชอบ)"
/// หรือคนที่ยังไม่ซื้อสูตร official ซึ่ง backend ไม่ส่งปริมาณมาให้
class RecipeIngredientLine {
  const RecipeIngredientLine({
    this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.note,
    this.isOptional = false,
  });

  final String? ingredientId;
  final String name;
  final double? amount;
  final String? unit;
  final String? note;
  final bool isOptional;

  /// แถวจาก recipeIngredients ของ GET /recipes/:id
  static RecipeIngredientLine? fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredient'];
    if (ingredient is! Map<String, dynamic>) return null;
    final name = ingredient['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final amount = json['amount'];
    return RecipeIngredientLine(
      ingredientId: ingredient['id'] as String?,
      name: name.trim(),
      // numeric ของ postgres มาเป็น string เช่น "200.000"
      amount: amount == null ? null : double.tryParse(amount.toString()),
      unit: _optionalText(json['unit']),
      note: _optionalText(json['preparationNote']),
      isOptional: json['isOptional'] as bool? ?? false,
    );
  }

  /// รูปแบบที่ส่งให้ backend ตอนสร้าง/แก้สูตร
  Map<String, dynamic> toPayload() => {
    if (ingredientId != null) 'ingredientId': ingredientId else 'name': name,
    'amount': amount,
    'unit': unit,
    'note': note,
    'isOptional': isOptional,
  };

  /// "200 กรัม", "1.5 ถ้วย", "2" (ไม่มีหน่วย) ไม่มีปริมาณ = ""
  String get amountLabel {
    final value = amount;
    final unitText = unit ?? '';
    if (value == null) return unitText;
    final number = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value
              .toStringAsFixed(3)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    return unitText.isEmpty ? number : '$number $unitText';
  }

  /// ชื่อเดียวกัน (ไม่สนตัวพิมพ์/ช่องว่างซ้ำ) แบบเดียวกับที่ backend จับคู่
  bool sameIngredientAs(RecipeIngredientLine other) {
    if (ingredientId != null && ingredientId == other.ingredientId) {
      return true;
    }
    return normalizeName(name).toLowerCase() ==
        normalizeName(other.name).toLowerCase();
  }

  static String normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? _optionalText(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// วัตถุดิบในคลัง (GET /ingredients) ใช้เป็นตัวเลือกตอนพิมพ์ชื่อ
class IngredientOption {
  const IngredientOption({required this.id, required this.name});

  final String id;
  final String name;

  static IngredientOption? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return IngredientOption(id: id, name: name);
  }
}
