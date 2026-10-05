import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/category_repository.dart';
import 'package:flutter_application_1/views/pages/create_foodcard_page.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/widgets/recipe_library/recipe_library_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class RecipeCollectionPage extends StatelessWidget {
  const RecipeCollectionPage({super.key, required this.collectionType});

  final RecipeCollectionType collectionType;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<RecipeLibraryBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is RecipeLibraryLoaded || state is RecipeLibraryFailure,
    );
    bloc.add(const RecipeLibraryRefreshRequested());
    await completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.background,
        foregroundColor: ProfileColors.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          collectionType.title(context.l10n),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (collectionType == RecipeCollectionType.myRecipes)
            const _AddRecipeButton(),
        ],
      ),
      body: BlocBuilder<RecipeLibraryBloc, RecipeLibraryState>(
        builder: (context, state) => RecipeCollectionBody(
          state: state,
          emptyMessage: collectionType.emptyMessage(context.l10n),
          onRefresh: () => _refresh(context),
          onRetry: () => context.read<RecipeLibraryBloc>().add(
            const RecipeLibraryRequested(),
          ),
          onLoadMore: () => context.read<RecipeLibraryBloc>().add(
            const RecipeLibraryMoreRequested(),
          ),
          onRecipeDeleted: (recipeId) => context.read<RecipeLibraryBloc>().add(
            RecipeLibraryItemRemoved(recipeId),
          ),
          // มีรายการอยู่แล้ว = อัปเดตเงียบ ๆ ไม่ขึ้นตัวหมุน
          onRecipeClosed: () => context.read<RecipeLibraryBloc>().add(
            const RecipeLibraryRefreshRequested(),
          ),
        ),
      ),
    );
  }
}

/// ปุ่ม + สร้างสูตรใหม่ (สร้างเป็น official มีช่องราคา)
class _AddRecipeButton extends StatefulWidget {
  const _AddRecipeButton();

  @override
  State<_AddRecipeButton> createState() => _AddRecipeButtonState();
}

class _AddRecipeButtonState extends State<_AddRecipeButton> {
  bool _isOpening = false;

  Future<void> _createRecipe() async {
    setState(() => _isOpening = true);

    try {
      // หน้าสร้างสูตรต้องมีรายการหมวดหมู่ทั้งหมดให้เลือก
      final categories = await CategoryRepository().fetchCategories();
      if (!mounted) return;
      setState(() => _isOpening = false);

      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => CreateFoodcardPage(
            categories: categories,
            isFromCommunity: false,
          ),
        ),
      );

      if (!mounted || created != true) return;
      context.read<RecipeLibraryBloc>().add(
        const RecipeLibraryRefreshRequested(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isOpening = false);
      showAppSnackBar(
        context,
        context.l10n.openEditorFailed('$error'),
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.createRecipeTooltip,
      onPressed: _isOpening ? null : _createRecipe,
      icon: _isOpening
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ProfileColors.ink,
              ),
            )
          : const Icon(Icons.add_rounded, size: 28),
    );
  }
}

/// ตัวกริดสูตร + empty/error/loading แยกออกมาให้หน้าที่ใช้ bloc อื่นใช้ร่วมได้
class RecipeCollectionBody extends StatelessWidget {
  const RecipeCollectionBody({
    super.key,
    required this.state,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onRetry,
    this.onLoadMore,
    this.onRecipeDeleted,
    this.onRecipeClosed,
  });

  /// ลบสูตรจากหน้ารายละเอียดแล้วกลับมา
  final ValueChanged<String>? onRecipeDeleted;

  /// กลับจากหน้ารายละเอียดสูตร (ลบหรือไม่ก็ตาม)
  final VoidCallback? onRecipeClosed;

  final RecipeLibraryState state;
  final String emptyMessage;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;

  /// เลื่อนใกล้ล่างสุดแล้ว ขอหน้าถัดไป (null = ไม่แบ่งหน้า)
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RecipeLibraryLoaded(:final recipes) when recipes.isEmpty => _EmptyView(
        message: emptyMessage,
        onRefresh: onRefresh,
      ),
      final RecipeLibraryLoaded loaded => RefreshIndicator(
        color: ProfileColors.ink,
        onRefresh: onRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // โหลดพลาดแล้วให้กดลองใหม่เอง ไม่วนยิงซ้ำตอนเลื่อน
            if (loaded.hasMore &&
                loaded.loadMoreError == null &&
                notification.metrics.extentAfter < 400) {
              onLoadMore?.call();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.67,
                  ),
                  itemCount: loaded.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = loaded.recipes[index];
                    return RecipeLibraryCard(
                      recipe: recipe,
                      onTap: () async {
                        // หน้ารายละเอียดคืน true = ลบสูตรไปแล้ว
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => FoodDetailPage(foodsId: recipe.id),
                          ),
                        );
                        if (deleted == true) onRecipeDeleted?.call(recipe.id);
                        // อาจแก้ไข/เผยแพร่สูตรมา อัปเดตรายการเงียบ ๆ
                        onRecipeClosed?.call();
                      },
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: _LoadMoreFooter(state: loaded, onRetry: onLoadMore),
                ),
              ),
            ],
          ),
        ),
      ),
      RecipeLibraryFailure(:final message) => _ErrorView(
        message: message,
        onRetry: onRetry,
      ),
      _ => const Center(
        child: CircularProgressIndicator(color: ProfileColors.ink),
      ),
    };
  }
}

/// ท้ายรายการ: ตัวหมุนตอนโหลดหน้าถัดไป หรือปุ่มลองใหม่ถ้าโหลดพลาด
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onRetry});

  final RecipeLibraryLoaded state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: ProfileColors.ink),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.loadFailedTryAgain),
        ),
      );
    }
    if (state.hasMore || state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: CircularProgressIndicator(color: ProfileColors.ink),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.onRefresh});

  final String message;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ProfileColors.ink,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.menu_book_rounded,
            color: ProfileColors.muted,
            size: 56,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ProfileColors.muted,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ProfileColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
