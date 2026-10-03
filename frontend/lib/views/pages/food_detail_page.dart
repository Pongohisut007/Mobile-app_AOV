import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/recipe_comment_repository.dart';
import 'package:flutter_application_1/repositories/recipe_review_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/cooking_steps_page.dart';
import 'package:flutter_application_1/views/pages/create_foodcard_page.dart';
import 'package:flutter_application_1/widgets/food_detail/bottom_buy_bar.dart';
import 'package:flutter_application_1/widgets/food_detail/error_view.dart';
import 'package:flutter_application_1/widgets/food_detail/fly_to_cart.dart';
import 'package:flutter_application_1/widgets/food_detail/food_description.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_header.dart';
import 'package:flutter_application_1/widgets/food_detail/food_info_card.dart';
import 'package:flutter_application_1/widgets/food_detail/loading_view.dart';
import 'package:flutter_application_1/widgets/recipe_chat/recipe_chat_button.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_section.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({
    super.key,
    required this.foodsId,
    this.showComments = false,
    this.scrollToComments = false,
    this.onCommentCountChanged,
  });

  final String foodsId;
  final bool showComments;
  final bool scrollToComments;
  final ValueChanged<int>? onCommentCountChanged;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final GlobalKey _commentsTitleKey = GlobalKey();

  // จุดเริ่มกับปลายทางของรูปที่ลอยลงตะกร้า
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey<CartBounceState> _cartKey = GlobalKey();

  late Future<Food> _foodFuture;

  bool _commentScrollScheduled = false;
  bool _isOpeningEditor = false;

  /// เมนูที่เพิ่งกด Buy Now รอผลจาก API ก่อนค่อยเล่น animation
  Food? _addingFood;

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
    // อ่านจาก state ที่โหลดไว้ทั้งแอป ไม่ต้องยิง API ใหม่ทุกครั้งที่เปิดหน้า
    // ยังโหลดไม่เสร็จก็ยังไม่โชว์ปุ่มซื้อ กันปุ่มโผล่แวบแล้วหายไป
    final canBuy = context.select((PurchasedRecipesBloc bloc) {
      final state = bloc.state;
      return state.isResolved && !state.isPurchased(widget.foodsId);
    });

    return BlocListener<CartBloc, CartState>(
      // เล่นเฉพาะตอนที่กดจากหน้านี้ และ API เพิ่มลงตะกร้าสำเร็จแล้ว
      listenWhen: (previous, current) =>
          _addingFood != null &&
          previous.isPending(widget.foodsId) &&
          !current.isPending(widget.foodsId),
      listener: (context, state) {
        final food = _addingFood;
        _addingFood = null;

        if (food != null && state.contains(food.idfoods)) {
          _playFlyToCart(food);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar:
            widget.showComments || widget.scrollToComments || !canBuy
                ? null
                : FutureBuilder<Food>(
                    future: _foodFuture,
                    builder: (context, snapshot) {
                      final food = snapshot.data;

                      final isPending = context.select(
                        (CartBloc bloc) =>
                            bloc.state.isPending(widget.foodsId),
                      );

                      final inCart = context.select(
                        (CartBloc bloc) =>
                            bloc.state.contains(widget.foodsId),
                      );

                      return BottomBuyBar(
                        cartKey: _cartKey,
                        onCartPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.cart),
                        buyLabel: inCart ? 'Checkout now' : 'Buy Now',
                        onBuyPressed: inCart
                            ? () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.cart,
                                )
                            : food == null || isPending
                                ? null
                                : () => _addToCart(food),
                      );
                    },
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
      ),
    );
  }

  Widget _buildBody(Food food) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            KeyedSubtree(
              key: _headerKey,
              child: FoodDetailHeader(
                food: food,
                onEdit: () => _editFood(food),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('ลบสูตรอาหาร'),
                        content: const Text(
                          'คุณต้องการลบสูตรอาหารนี้ใช่หรือไม่?\n'
                          'ข้อมูลที่เกี่ยวข้องทั้งหมดจะถูกลบด้วย',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text(
                              'ลบ',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true || !context.mounted) {
                    return;
                  }

                  await FoodRepository().deleteFood(food.idfoods);

                  Navigator.pop(context, true);
                },
              ),
            ),

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

                  FoodDescription(description: food.description),

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

                  const SizedBox(height: 12),

                  // แสดงเฉพาะคนที่ซื้อสูตรแล้ว
                  RecipeChatButton(recipeId: food.idfoods),

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
                      )..add(
                          const RecipeCommentsRequested(),
                        ),
                      child: RecipeCommentSection(
                        headingKey: _commentsTitleKey,
                        onReady: _scheduleScrollToComments,
                        onCommentCountChanged:
                            widget.onCommentCountChanged,
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

  Future<void> _editFood(Food food) async {
    if (_isOpeningEditor) return;

    _isOpeningEditor = true;

    try {
      // หน้าแก้ไขต้องมีรายการหมวดหมู่ทั้งหมด
      // เพื่อให้เลือก/แสดงหมวดเดิมได้
      final categories =
          await CategoryRepository().fetchCategories();

      if (!mounted) return;

      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => CreateFoodcardPage(
            categories: categories,
            isFromCommunity: food.type != 'official',
            initialFood: food,
          ),
        ),
      );

      if (!mounted || updated != true) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('บันทึกการแก้ไขแล้ว'),
          ),
        );

      _reload();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
          ),
        );
    } finally {
      _isOpeningEditor = false;
    }
  }

  Future<void> _addToCart(Food food) async {
    final cartBloc = context.read<CartBloc>();

    if (await _requireSignIn(context)) return;

    _addingFood = food;

    cartBloc.add(
      CartItemAdded(
        food,
        showFeedback: false,
      ),
    );
  }

  void _playFlyToCart(Food food) {
    final cartRect = _cartKey.currentState?.globalRect;

    if (cartRect == null) return;

    const imageSize = 140.0;

    final headerBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;

    final headerCenter =
        headerBox != null && headerBox.attached
            ? headerBox.localToGlobal(
                headerBox.size.center(Offset.zero),
              )
            : null;

    // ถ้าเลื่อนจนรูปพ้นจอไปแล้ว
    // ให้เริ่ม animation จากกลางจอแทน
    final screen = MediaQuery.sizeOf(context);

    final start =
        headerCenter != null &&
                headerCenter.dy > imageSize / 2
            ? headerCenter
            : Offset(
                screen.width / 2,
                screen.height / 2,
              );

    flyToCart(
      context: context,
      imageUrl: food.filePathImage,
      from: Rect.fromCenter(
        center: start,
        width: imageSize,
        height: imageSize,
      ),
      to: cartRect,
      onArrived: () => _cartKey.currentState?.bounce(),
    );
  }

  void _scheduleScrollToComments() {
    if (!widget.scrollToComments) return;

    if (_commentScrollScheduled) return;

    _commentScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext =
          _commentsTitleKey.currentContext;

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

/// ตะกร้าผูกกับบัญชี
/// ยังไม่ล็อกอินก็เด้งไปหน้า login ก่อน
///
/// คืน true เมื่อไปต่อไม่ได้
/// ผู้เรียกต้องหยุดทำงานต่อ
Future<bool> _requireSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);

  final accessToken =
      await TokenStorage().readAccessToken();

  if (accessToken != null &&
      accessToken.trim().isNotEmpty) {
    return false;
  }

  if (!context.mounted) return true;

  navigator.pushNamed(AppRoutes.login);

  return true;
}