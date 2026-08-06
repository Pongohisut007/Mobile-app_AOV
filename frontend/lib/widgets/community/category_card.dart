import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const fallbackImage =
        'https://islamspk.com/masjid/no-pict-board.png';
    final rawImageUrl = category.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? fallbackImage : rawImageUrl;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 130,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                fallbackImage,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      ),
    );
  }
}