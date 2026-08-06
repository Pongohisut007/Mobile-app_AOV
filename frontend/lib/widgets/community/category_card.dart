import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  const CategoryCard({super.key});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print("Card Click");
        },
        child: SizedBox(
          height: 206,
          width: double.infinity,
          child: Image.network(
            "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}