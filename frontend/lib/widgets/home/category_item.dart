import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        final isSelected = state.selectedCategory == title;

        return InkWell(
          onTap: () {
            categoryBloc.add(CategorySelectEvent(title));
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}