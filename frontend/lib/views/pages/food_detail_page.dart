import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/recipe_comment_repository.dart';
import 'package:flutter_application_1/repositories/recipe_review_repository.dart';
import 'package:flutter_application_1/views/pages/cooking_steps_page.dart';
import 'package:flutter_application_1/widgets/food_detail/bottom_buy_bar.dart';
import 'package:flutter_application_1/widgets/food_detail/error_view.dart';
import 'package:flutter_application_1/widgets/food_detail/food_description.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_header.dart';
import 'package:flutter_application_1/widgets/food_detail/food_info_card.dart';
import 'package:flutter_application_1/widgets/food_detail/loading_view.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_section.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({
    super.key,
    required this.foodsId,
    this.showComments = false,
    this.scrollToComments = false,
    this.onCommentSubmitted,
  });

  final String foodsId;
  final bool showComments;
  final bool scrollToComments;
  final VoidCallback? onCommentSubmitted;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final GlobalKey _commentsTitleKey = GlobalKey();

  late Future<Food> _foodFuture;

  bool _commentScrollScheduled = false;

  @override
  void initState() {
    super.initState();

    _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
  }

  void _reload() {
    setState(() {
      _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
      _commentScrollScheduled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        bottomNavigationBar: widget.showComments || widget.scrollToComments
          ? null
          : BottomBuyBar(
              onCartPressed: () {},
              onBuyPressed: () {},
            ),
      body: FutureBuilder<Food>(
        future: _foodFuture,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (state.hasError || !state.hasData) {
            return ErrorView(
              message: state.error?.toString() ?? 'ไม่พบข้อมูลเมนูนี้',
              onRetry: _reload,
            );
          }

          return _buildBody(state.data!);
        },
      ),
    );
  }

  Widget _buildBody(Food food) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            FoodDetailHeader(food: food),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 33),

                  FoodInfoCard(food: food),

                  const SizedBox(height: 30),

                  FoodDescription(
                    description: food.description,
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CookingStepsPage(food: food),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6650A5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(
                        Icons.restaurant_menu_rounded,
                      ),
                      label: const Text(
                        'เริ่มทำอาหาร',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Divider(
                    color: Colors.grey.shade200,
                    height: 1,
                  ),

                  const SizedBox(height: 28),

                  if (widget.showComments || widget.scrollToComments)
                    BlocProvider(
                      create: (_) => RecipeCommentBloc(
                        HttpRecipeCommentRepository(
                          baseUrl: ApiConfig.apiBaseUrl,
                        ),
                        recipeId: food.idfoods,
                      )..add(const RecipeCommentsRequested()),
                      child: RecipeCommentSection(
                        headingKey: _commentsTitleKey,
                        onReady: _scheduleScrollToComments,
                        onCommentSubmitted: widget.onCommentSubmitted,
                      ),
                    )
                  else
                    BlocProvider(
                      create: (_) => RecipeReviewBloc(
                        HttpRecipeReviewRepository(
                          baseUrl: ApiConfig.apiBaseUrl,
                        ),
                        recipeId: food.idfoods,
                      )..add(
                          const RecipeReviewRequested(),
                        ),
                      child: const RecipeReviewSection(),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleScrollToComments() {
    if (!widget.scrollToComments) return;

    if (_commentScrollScheduled) return;

    _commentScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext = _commentsTitleKey.currentContext;

      if (targetContext == null) {
        _commentScrollScheduled = false;
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }
}