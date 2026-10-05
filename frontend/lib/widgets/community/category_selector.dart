import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// แถบหมวดหมู่ของหน้า community เป็นชิปแคปซูล (ต่างจากไทล์ของหน้า Home)
/// ใช้สี ink/accent แบบหน้า Profile และไอคอนชุดเดียวกับหน้า Home
/// เก็บหมวดที่เลือกไว้เอง ไม่ไปเปลี่ยนหมวดของหน้า Home
class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final ValueChanged<String?> onCategorySelected;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  // null = ทั้งหมด
  String? _selectedId;

  void _select(String? id) {
    // แตะหมวดเดิมซ้ำ = กลับไปทั้งหมด
    final next = _selectedId == id ? null : id;
    if (next == _selectedId) return;
    setState(() => _selectedId = next);
    widget.onCategorySelected(next);
  }

  @override
  Widget build(BuildContext context) {
    // ListView ตัดทุกอย่างที่ล้นกรอบ เผื่อที่ด้านล่าง/ข้าง ๆ ให้เงาของชิปไม่ขาด
    // (ชิปยังสูง 42 เท่าเดิม)
    return SizedBox(
      height: 42 + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        itemCount: widget.categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _CategoryChip(
              icon: Icons.apps_rounded,
              label: context.l10n.categoryAll,
              isSelected: _selectedId == null,
              onTap: () => _select(null),
            );
          }
          final category = widget.categories[index - 1];
          return _CategoryChip(
            icon: CategoryList.iconFor(category.slug),
            label: category.name,
            isSelected: _selectedId == category.id,
            onTap: () => _select(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
          decoration: ShapeDecoration(
            color: isSelected ? ProfileColors.ink : Colors.white,
            shadows: AppShadows.chip,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? ProfileColors.ink : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? ProfileColors.accent
                    : const Color(0xFFE64A19),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : ProfileColors.ink,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
