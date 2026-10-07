import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
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
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/food_detail/bottom_buy_bar.dart';
import 'package:flutter_application_1/widgets/food_detail/error_view.dart';
import 'package:flutter_application_1/widgets/food_detail/fly_to_cart.dart';
import 'package:flutter_application_1/widgets/food_detail/food_author.dart';
import 'package:flutter_application_1/widgets/food_detail/food_description.dart';
import 'package:flutter_application_1/widgets/food_detail/food_ingredients.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_header.dart';
import 'package:flutter_application_1/widgets/food_detail/food_categories.dart';
import 'package:flutter_application_1/widgets/food_detail/food_info_card.dart';
import 'package:flutter_application_1/widgets/common/route_transition_aware.dart';
import 'package:flutter_application_1/widgets/food_detail/food_image.dart';
import 'package:flutter_application_1/widgets/food_detail/loading_view.dart';
import 'package:flutter_application_1/widgets/recipe_chat/recipe_chat_button.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_section.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({
    super.key,
    required this.foodsId,
    this.showComments = false,
    this.scrollToComments = false,
    this.onCommentCountChanged,
    this.heroImageUrl,
  });

  final String foodsId;

  /// รูปจากการ์ดที่กดเข้ามา (มี Hero tag = foodsId)
  /// ระหว่างโหลดสูตรครั้งแรกจะโชว์รูปนี้เป็นหัวหน้าไว้ก่อน รูปจะได้บินจากการ์ดมาได้
  final String? heroImageUrl;
  final bool showComments;
  final bool scrollToComments;
  final ValueChanged<int>? onCommentCountChanged;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with RouteTransitionAware {
  final GlobalKey _commentsTitleKey = GlobalKey();

  // จุดเริ่มกับปลายทางของรูปที่ลอยลงตะกร้า
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey<CartBounceState> _cartKey = GlobalKey();

  late Future<Food> _foodFuture;

  // ข้อมูลจาก RAM ตอนเปิดหน้า (เคยเปิดสูตรนี้แล้ว) โชว์ทันทีโดยไม่ต้องรอ API
  Food? _cachedFood;

  bool _commentScrollScheduled = false;
  bool _isOpeningEditor = false;
  bool _isDeleting = false;
  bool _isStartingCooking = false;
  // สูตร community ต้อง login ก่อนถึงจะเห็นปุ่มเริ่มทำอาหาร
  bool _isLoggedIn = false;

  // เพิ่มทุกครั้งที่ดึงลง refresh ใช้เป็น key ให้รีวิว/คอมเมนต์โหลดใหม่ด้วย
  int _refreshCount = 0;

  /// เมนูที่เพิ่งกด Buy Now รอผลจาก API ก่อนค่อยเล่น animation
  Food? _addingFood;

  @override
  void initState() {
    super.initState();

    final cached = FoodRepository.cachedFood(widget.foodsId);
    if (cached != null) {
      // โชว์ของเดิมทันที แล้วโหลดของใหม่มาแทนเงียบ ๆ
      _cachedFood = cached;
      _foodFuture = Future.value(cached);
      _refresh(silent: true);
    } else {
      // ยิง API ทันที แต่เอาเนื้อหาขึ้นจอหลังเลื่อนหน้าเสร็จ ไม่ให้ build ก้อนใหญ่ระหว่างแอนิเมชัน
      // เคยเปิดสูตรนี้ (แม้ปิดแอปไปแล้ว) = โชว์ของในเครื่องก่อน แล้วโหลดของใหม่มาแทนเงียบ ๆ
      _foodFuture = afterRouteTransition(_loadSavedOrFetch());
    }
    _loadLoginState();
  }

  Future<Food> _loadSavedOrFetch() async {
    final saved = await FoodRepository.loadCachedFood(widget.foodsId);
    if (saved == null) return FoodRepository().fetchFoodById(widget.foodsId);
    _cachedFood = saved;
    unawaited(_refresh(silent: true));
    return saved;
  }

  Future<void> _loadLoginState() async {
    final accessToken = await TokenStorage().readAccessToken();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = accessToken != null && accessToken.trim().isNotEmpty;
    });
  }

  void _reload() {
    setState(() {
      _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
      _commentScrollScheduled = false;
    });
  }

  // ดึงลงเพื่อโหลดใหม่: โชว์ข้อมูลเดิมไว้ระหว่างรอ โหลดพลาดก็ไม่ทับของเดิม
  // silent = อัปเดตเบื้องหลังตอนเปิดหน้าจาก RAM: ไม่โหลดรีวิว/คอมเมนต์ซ้ำ และไม่เด้ง error
  Future<void> _refresh({bool silent = false}) async {
    try {
      final food = await afterRouteTransition(
        FoodRepository().fetchFoodById(widget.foodsId),
      );
      if (!mounted) return;
      setState(() {
        _foodFuture = Future.value(food);
        _cachedFood = food;
        if (!silent) _refreshCount++;
      });
    } catch (error) {
      if (!mounted || silent) return;
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // อ่านจาก state ที่โหลดไว้ทั้งแอป ไม่ต้องยิง API ใหม่ทุกครั้งที่เปิดหน้า
    // ยังโหลดไม่เสร็จก็ยังไม่โชว์ปุ่มซื้อ กันปุ่มโผล่แวบแล้วหายไป
    // context.select ต้องเรียกใน build() เท่านั้น จึงอ่านไว้ตรงนี้แล้วส่งต่อให้ _buildBody
    final isPurchased = context.select(
      (PurchasedRecipesBloc bloc) => bloc.state.isPurchased(widget.foodsId),
    );
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
      // เพิ่งซื้อสูตรนี้ (จากตะกร้า) โหลดใหม่ให้ได้ขั้นตอนและปริมาณวัตถุดิบครบ
      child: BlocListener<PurchasedRecipesBloc, PurchasedRecipesState>(
        listenWhen: (previous, current) =>
            !previous.isPurchased(widget.foodsId) &&
            current.isPurchased(widget.foodsId),
        listener: (_, _) => _refresh(silent: true),
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar:
              widget.showComments || widget.scrollToComments || !canBuy
              ? null
              : FutureBuilder<Food>(
                  future: _foodFuture,
                  initialData: _cachedFood,
                  builder: (context, snapshot) {
                    final food = snapshot.data;
                    // สูตร community ฟรี และสูตรของตัวเอง ไม่มีปุ่มซื้อ ไม่ว่าจะเข้ามาจากหน้าไหน
                    if (food != null &&
                        (_isCommunity(food) || _isOwnRecipe(food))) {
                      return const SizedBox.shrink();
                    }

                    final isPending = context.select(
                      (CartBloc bloc) => bloc.state.isPending(widget.foodsId),
                    );

                    final inCart = context.select(
                      (CartBloc bloc) => bloc.state.contains(widget.foodsId),
                    );

                    return BottomBuyBar(
                      cartKey: _cartKey,
                      isLoading: isPending,
                      onCartPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.cart),
                      buyLabel: inCart
                          ? context.l10n.checkoutNow
                          : context.l10n.buyNow,
                      onBuyPressed: inCart
                          ? () => Navigator.pushNamed(context, AppRoutes.cart)
                          : food == null || isPending
                          ? null
                          : () => _addToCart(food),
                    );
                  },
                ),
          body: FutureBuilder<Food>(
            future: _foodFuture,
            initialData: _cachedFood,
            builder: (context, state) {
              // มีข้อมูลเดิมอยู่แล้ว (เช่นหลังแก้ไขสูตร) ให้โชว์ของเดิมไว้ระหว่างโหลด
              if (state.connectionState == ConnectionState.waiting &&
                  !state.hasData) {
                final heroImageUrl = widget.heroImageUrl;
                return LoadingView(
                  header: heroImageUrl == null
                      ? null
                      : FoodImage(
                          heroTag: widget.foodsId,
                          imageUrl: heroImageUrl,
                        ),
                );
              }

              if (state.hasError || !state.hasData) {
                return ErrorView(
                  message:
                      state.error?.toString() ?? context.l10n.recipeNotFound,
                  onRetry: _reload,
                );
              }

              return _buildBody(state.data!, isPurchased: isPurchased);
            },
          ),
        ),
      ),
    );
  }

  // สูตร community ใช้คอมเมนต์ ส่วน official ใช้รีวิว
  // ดูจาก type ของสูตรเอง เพราะเข้าหน้านี้ได้จากหลายที่ (Profile, Home ฯลฯ)
  bool _isCommunity(Food food) => food.type == 'community';

  // สูตรของตัวเองซื้อไม่ได้ (backend ไม่ให้ซื้ออยู่แล้ว)
  bool _isOwnRecipe(Food food) {
    final userId = TokenStorage.currentUserId.value;
    return userId != null && food.creatorId == userId;
  }

  Widget _buildBody(Food food, {required bool isPurchased}) {
    // official ที่ยังไม่ได้ซื้อ ไม่ให้เริ่มทำอาหาร
    // เช็กการซื้อด้วย เพราะเพิ่งซื้อในหน้านี้ข้อมูลสูตรยังไม่ได้โหลดใหม่
    // สูตร community ไม่ login ก็ไม่ให้เริ่มทำอาหาร
    final canStartCooking =
        (food.canViewFullRecipe || isPurchased) &&
        (!_isCommunity(food) || _isLoggedIn);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              KeyedSubtree(
                key: _headerKey,
                child: FoodDetailHeader(
                  food: food,
                  isBusy: _isOpeningEditor || _isDeleting,
                  onEdit: () => _editFood(food),
                  onDelete: () => _deleteFood(food),
                ),
              ),

              Padding(
                key: ValueKey(_refreshCount),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.displayName(context),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // ไม่มีทั้ง id และชื่อ = backend ไม่ได้ส่งเจ้าของมา ไม่ต้องโชว์
                    if (food.creatorId != null || food.creatorName != null) ...[
                      const SizedBox(height: 10),
                      FoodAuthor(
                        name: food.creatorName,
                        avatarUrl: food.creatorAvatar,
                      ),
                    ],

                    if (food.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      FoodCategories(categories: food.categories),
                    ],

                    const SizedBox(height: 33),

                    FoodInfoCard(food: food),

                    const SizedBox(height: 30),

                    FoodDescription(description: food.description),

                    const SizedBox(height: 28),

                    if (food.ingredients.isNotEmpty) ...[
                      FoodIngredients(
                        ingredients: food.ingredients,
                        // ซื้อในหน้านี้แล้วแต่ยังไม่ได้โหลดสูตรใหม่ ก็ยังไม่มีปริมาณให้แสดง
                        amountsLocked: !food.canViewFullRecipe,
                      ),
                      const SizedBox(height: 28),
                    ],

                    if (canStartCooking) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isStartingCooking
                              ? null
                              : () => _startCooking(food),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6650A5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: _isStartingCooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.restaurant_menu_rounded),
                          label: Text(
                            context.l10n.startCooking,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],

                    // แสดงเฉพาะคนที่ซื้อสูตรแล้ว และสูตรต้องไม่ใช่ฉบับร่าง
                    if (food.status != 'draft')
                      RecipeChatButton(recipeId: food.idfoods),

                    const SizedBox(height: 32),

                    Divider(color: Colors.grey.shade200, height: 1),

                    const SizedBox(height: 28),

                    // เปิดจาก RAM เนื้อหาขึ้นตั้งแต่เฟรมแรก รอเลื่อนหน้าเสร็จก่อนค่อยโหลด/วาดรีวิวกับคอมเมนต์
                    if (!isRouteTransitionDone)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (widget.showComments ||
                        widget.scrollToComments ||
                        _isCommunity(food))
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
                          onCommentCountChanged: widget.onCommentCountChanged,
                        ),
                      )
                    else
                      BlocProvider(
                        create: (_) => RecipeReviewBloc(
                          HttpRecipeReviewRepository(
                            baseUrl: ApiConfig.apiBaseUrl,
                          ),
                          recipeId: food.idfoods,
                        )..add(const RecipeReviewRequested()),
                        child: const RecipeReviewSection(),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startCooking(Food food) async {
    if (_isStartingCooking) return;
    setState(() => _isStartingCooking = true);

    try {
      var target = food;
      // เพิ่งซื้อในหน้านี้ ข้อมูลที่มียังมีแค่ขั้นตอน preview ต้องโหลดใหม่ก่อน
      if (!food.canViewFullRecipe) {
        await _refresh();
        if (!mounted) return;
        target = await _foodFuture;
        if (!mounted) return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CookingStepsPage(food: target)),
      );
    } finally {
      if (mounted) setState(() => _isStartingCooking = false);
    }
  }

  Future<void> _deleteFood(Food food) async {
    if (_isDeleting) return;

    final confirmed = await showAppConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: context.l10n.deleteRecipe,
      message: context.l10n.deleteRecipeConfirm,
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
      danger: true,
    );

    if (!confirmed || !mounted || _isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      await FoodRepository().deleteFood(food.idfoods);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showError(error);
    }
  }

  Future<void> _editFood(Food food) async {
    if (_isOpeningEditor || _isDeleting) return;

    setState(() => _isOpeningEditor = true);

    try {
      // หน้าแก้ไขต้องมีรายการหมวดหมู่ทั้งหมด
      // เพื่อให้เลือก/แสดงหมวดเดิมได้
      final categories = await CategoryRepository().fetchCategories();

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

      showAppSnackBar(
        context,
        context.l10n.changesSaved,
        type: AppSnackType.success,
      );

      _reload();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _isOpeningEditor = false);
    }
  }

  void _showError(Object error) {
    showAppSnackBar(
      context,
      error.toString().replaceFirst('Exception: ', ''),
      type: AppSnackType.error,
    );
  }

  Future<void> _addToCart(Food food) async {
    final cartBloc = context.read<CartBloc>();

    if (await _requireSignIn(context)) return;

    _addingFood = food;

    cartBloc.add(CartItemAdded(food, showFeedback: false));
  }

  void _playFlyToCart(Food food) {
    final cartRect = _cartKey.currentState?.globalRect;

    if (cartRect == null) return;

    const imageSize = 140.0;

    final headerBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;

    final headerCenter = headerBox != null && headerBox.attached
        ? headerBox.localToGlobal(headerBox.size.center(Offset.zero))
        : null;

    // ถ้าเลื่อนจนรูปพ้นจอไปแล้ว
    // ให้เริ่ม animation จากกลางจอแทน
    final screen = MediaQuery.sizeOf(context);

    final start = headerCenter != null && headerCenter.dy > imageSize / 2
        ? headerCenter
        : Offset(screen.width / 2, screen.height / 2);

    flyToCart(
      context: context,
      imageUrl: food.filePathImage,
      from: Rect.fromCenter(center: start, width: imageSize, height: imageSize),
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

/// ตะกร้าผูกกับบัญชี
/// ยังไม่ล็อกอินก็เด้งไปหน้า login ก่อน
///
/// คืน true เมื่อไปต่อไม่ได้
/// ผู้เรียกต้องหยุดทำงานต่อ
Future<bool> _requireSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);

  final accessToken = await TokenStorage().readAccessToken();

  if (accessToken != null && accessToken.trim().isNotEmpty) {
    return false;
  }

  if (!context.mounted) return true;

  navigator.pushNamed(AppRoutes.login);

  return true;
}
