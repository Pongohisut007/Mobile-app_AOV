import 'dart:async';

import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.controller,
    this.showNotificationButton = true,
  });

  // ส่งคำค้นหาออกไปหลังผู้ใช้หยุดพิมพ์ ถ้าได้ค่าว่างคือยกเลิกการค้นหา
  final ValueChanged<String> onSearch;

  /// ใช้ข้อความร่วมกับช่องค้นหาอื่น (เช่น ช่องค้นหาบน app bar หน้า community)
  /// ถ้าส่งมา ผู้ส่งต้องกันการยิงคำซ้ำเอง เพราะอีกช่องอาจเพิ่งส่งคำเดียวกันไปแล้ว
  final TextEditingController? controller;

  final bool showNotificationButton;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // หน่วงก่อนยิง API ไม่งั้นพิมพ์ 1 ตัวอักษรจะยิง 1 ครั้ง
  static const _debounceDuration = Duration(milliseconds: 400);

  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  Timer? _debounce;
  String _lastSent = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ownController?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _submit(value));
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _submit(value);
  }

  void _submit(String value) {
    final query = value.trim();
    // กันยิงซ้ำคำเดิม เช่น พิมพ์เว้นวรรคท้ายคำ หรือกด enter ซ้ำ
    // (ใช้ controller ร่วมกับช่องอื่น ให้ผู้ส่ง controller กันซ้ำเอง)
    if (widget.controller == null) {
      if (query == _lastSent) return;
      _lastSent = query;
    }
    widget.onSearch(query);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _submit('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.search),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _onSubmitted,
                    decoration: const InputDecoration(
                      hintText: "search for a recipe",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                // ปุ่มล้างคำค้นหา โผล่เฉพาะตอนมีข้อความในช่อง
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _clear,
                      child: const Icon(Icons.close, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (widget.showNotificationButton) ...[
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.notifications_none),
          ),
        ],
      ],
    );
  }
}
