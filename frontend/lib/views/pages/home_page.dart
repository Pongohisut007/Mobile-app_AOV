import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/views/pages/food_detail_pageg.dart';
import 'package:flutter_application_1/widgets/home/category_list.dart';
import 'package:flutter_application_1/widgets/home/food_card.dart';
import 'package:flutter_application_1/widgets/home/home_banner.dart';
import 'package:flutter_application_1/widgets/home/search_bar.dart';
import 'package:flutter_application_1/widgets/home/section_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // call food bloc on init
   context.read<FoodBloc>().add(FetchFoodEvent());
  }

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

              BlocBuilder<FoodBloc, FoodState>(
                builder: (context, state) {
                  if (state is FoodInitial) {
                    return const Center(child: Text("Initial Loading..."));
                  }
                  if (state is FoodLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is FoodLoaded) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.foods.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .68,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemBuilder: (_, index) {
                        final food = state.foods[index];
                        return FoodCard(
                          food: food,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FoodDetailPage(foodsId: food.idfoods),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  // handle error state
                  if (state is FoodError) {
                    return Center(child: Text(state.message));
                  }
                  // return empty widget
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
