import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
import 'package:flutter_application_1/widgets/home/home_banner.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_application_1/widgets/home/section_title.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SearchBarWidget(),

              const SizedBox(height: 20),

              const HomeBanner(),

              const SizedBox(height: 25),

              const CategoryList(),

              const SizedBox(height: 25),

              const SectionTitle(),

              const SizedBox(height: 20),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 11,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .68,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (_, __) => const FoodCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
