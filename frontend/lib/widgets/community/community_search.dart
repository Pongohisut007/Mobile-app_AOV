import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';

class CommunitySearch extends StatelessWidget {
  const CommunitySearch({
    super.key,
    required this.onSearch,
  });

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      onSearch: onSearch,
    );
  }
}