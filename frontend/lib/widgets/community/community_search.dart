import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';

class CommunitySearch extends StatelessWidget {
  const CommunitySearch({
    super.key,
    required this.onSearch,
    this.controller,
  });

  final ValueChanged<String> onSearch;

  /// ใช้ข้อความร่วมกับช่องค้นหาบน app bar
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      onSearch: onSearch,
      controller: controller,
    );
  }
}
