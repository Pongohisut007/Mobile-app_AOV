import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';

class CommunitySearch extends StatelessWidget {
  const CommunitySearch({
    super.key,
    required this.onSearch,
    this.controller,
    this.focusNode,
  });

  final ValueChanged<String> onSearch;

  /// ที่เก็บคำค้นหาของหน้า community (ช่องนี้คือช่องค้นหาหลัก)
  final TextEditingController? controller;

  /// พิมพ์จากช่องบน app bar แล้ว หน้า community จะย้ายเคอร์เซอร์มาที่ช่องนี้
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      onSearch: onSearch,
      controller: controller,
      focusNode: focusNode,
    );
  }
}
