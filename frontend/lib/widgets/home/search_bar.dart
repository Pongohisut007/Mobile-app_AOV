import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.controller,
    this.focusNode,
    this.showNotificationButton = true,
    this.initialQuery = '',
  });

  // ส่งคำค้นหาออกไปหลังผู้ใช้หยุดพิมพ์ ถ้าได้ค่าว่างคือยกเลิกการค้นหา
  final ValueChanged<String> onSearch;

  /// ใช้ข้อความร่วมกับช่องค้นหาอื่น (เช่น ช่องค้นหาบน app bar หน้า community)
  /// ถ้าส่งมา ผู้ส่งเป็นคนฟังข้อความที่เปลี่ยน หน่วงเวลา และกันยิงคำซ้ำเอง
  /// ช่องนี้จะเรียก onSearch เฉพาะตอนกด enter และตอนกดล้าง
  final TextEditingController? controller;

  /// ให้ข้างนอกสั่งย้ายเคอร์เซอร์มาที่ช่องนี้ได้
  final FocusNode? focusNode;

  final bool showNotificationButton;

  /// คำค้นหาที่ใส่ไว้ในช่องตั้งแต่เปิดหน้า (ถือว่าค้นหาไปแล้ว ไม่ยิงซ้ำ)
  /// ใช้เฉพาะตอนไม่ได้ส่ง controller มา
  final String initialQuery;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // หน่วงก่อนยิง API ไม่งั้นพิมพ์ 1 ตัวอักษรจะยิง 1 ครั้ง
  static const _debounceDuration = Duration(milliseconds: 400);

  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialQuery));
  Timer? _debounce;
  late String _lastSent = widget.initialQuery.trim();

  @override
  void dispose() {
    _debounce?.cancel();
    _ownController?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // controller จากข้างนอก: เจ้าของ controller หน่วงเวลาเอง จะได้มีตัวหน่วงตัวเดียว
    if (widget.controller != null) return;
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
    // (controller จากข้างนอก ให้เจ้าของกันซ้ำเอง)
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
                    focusNode: widget.focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _onSubmitted,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchRecipeHint,
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
