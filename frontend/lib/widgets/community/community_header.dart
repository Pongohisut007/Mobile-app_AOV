import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// App bar ของหน้า community: หัวข้อ "Community" + ปุ่มค้นหา + ปุ่มสร้างสูตร
/// ติดอยู่ด้านบน ไม่เลื่อนตามรายการโพสต์
///
/// ปุ่มค้นหาโผล่เมื่อเลื่อนผ่านแถบหมวดหมู่ไปแล้ว (หน้า community เป็นคนบอก)
/// กดแล้วปุ่มจะยืดไปทางซ้ายจนเต็มแถบ คำว่า Community จางหาย แล้วพิมพ์ค้นหาได้
class CommunityHeader extends StatefulWidget implements PreferredSizeWidget {
  const CommunityHeader({
    super.key,
    required this.isIpad,
    required this.onAddPressed,
    required this.searchController,
    required this.showSearchButton,
    required this.isSearchExpanded,
    required this.onSearchPressed,
    required this.onSearchClosed,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final bool isIpad;

  /// null = ยังกดไม่ได้ (เช่น หมวดหมู่ยังโหลดไม่เสร็จ)
  final VoidCallback? onAddPressed;

  /// ข้อความเดียวกับช่องค้นหาในหน้า
  final TextEditingController searchController;
  final bool showSearchButton;
  final bool isSearchExpanded;
  final VoidCallback onSearchPressed;
  final VoidCallback onSearchClosed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<CommunityHeader> createState() => _CommunityHeaderState();
}

class _CommunityHeaderState extends State<CommunityHeader> {
  static const _buttonSize = 46.0;
  static const _duration = Duration(milliseconds: 280);

  // แสดงช่องพิมพ์หลังยืดเสร็จ ไม่งั้นช่องพิมพ์จะถูกบีบตอนปุ่มยังแคบอยู่
  bool _showField = false;

  @override
  void didUpdateWidget(covariant CommunityHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSearchExpanded) _showField = false;
  }

  @override
  Widget build(BuildContext context) {
    final expanded = widget.isSearchExpanded;

    return AppBar(
      backgroundColor: Colors.grey.shade100,
      surfaceTintColor: Colors.transparent,
      // เลื่อนรายการลอดใต้แถบแล้วไม่ต้องเปลี่ยนสี/มีเงา
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      titleSpacing: 16,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = expanded
              ? constraints.maxWidth
              : (widget.showSearchButton ? _buttonSize : 0.0);

          return SizedBox(
            height: _buttonSize,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: _duration,
                    opacity: expanded ? 0 : 1,
                    child: Text(
                      'Community',
                      style: TextStyle(
                        color: ProfileColors.ink,
                        fontSize: widget.isIpad ? 34 : 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  width: pillWidth,
                  height: _buttonSize,
                  clipBehavior: Clip.antiAlias,
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: StadiumBorder(),
                  ),
                  onEnd: () {
                    if (widget.isSearchExpanded && !_showField) {
                      setState(() => _showField = true);
                    }
                  },
                  child: _showField && expanded
                      ? _buildField()
                      : pillWidth == 0
                      ? null
                      : _buildSearchButton(),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton.filled(
          onPressed: widget.onAddPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ProfileColors.ink,
            fixedSize: const Size(_buttonSize, _buttonSize),
          ),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Create recipe',
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      onPressed: widget.isSearchExpanded ? null : widget.onSearchPressed,
      color: ProfileColors.ink,
      icon: const Icon(Icons.search_rounded),
      tooltip: 'Search',
    );
  }

  Widget _buildField() {
    return Row(
      children: [
        const SizedBox(width: 15),
        const Icon(Icons.search_rounded, color: ProfileColors.ink),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: widget.searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: widget.onSearchChanged,
            onSubmitted: widget.onSearchSubmitted,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'search for a recipe',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
        // ปิดช่องค้นหา (คำที่ค้นหายังคงอยู่)
        IconButton(
          onPressed: widget.onSearchClosed,
          color: ProfileColors.muted,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close search',
        ),
      ],
    );
  }
}
