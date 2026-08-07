import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/views/pages/community_selectcategory_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    const fallbackImage =
        'https://st2.depositphotos.com/3904951/8925/v/450/depositphotos_89250312-stock-illustration-photo-picture-web-icon-in.jpg';
    final rawImageUrl = category.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? fallbackImage : rawImageUrl;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(
                        value: context.read<CategoryBloc>(),
                      ),
                      BlocProvider(
                        create: (_) => FoodBloc(
                          FoodRepository(),
                        ),
                      ),
                    ],
                    child: CommunitySelectCategoryPage(
                      categoryUUID: category.id,
                      categoryImageUrl: imageUrl,
                    ),
                  ),
                ),
              );
            },
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