import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/views/pages/recipe_collection_page.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// อ่านจาก PurchasedRecipesBloc ที่โหลดไว้ทั้งแอป เปิดหน้านี้จึงไม่ยิง API ใหม่
/// อยากได้ข้อมูลล่าสุดก็ดึงลงเพื่อ refresh
class PurchasedRecipesPage extends StatelessWidget {
  const PurchasedRecipesPage({super.key});

  static const _collectionType = RecipeCollectionType.purchased;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PurchasedRecipesBloc>();
    final completed = bloc.stream.firstWhere((state) => state.isResolved);
    bloc.add(const PurchasedRecipesRefreshed());
    await completed;
  }

  // แปลงเป็น state ของหน้าคลังสูตร จะได้ใช้ RecipeCollectionBody ตัวเดียวกัน
  // มีรายการเก่าอยู่แล้ว ระหว่าง refresh หรือ refresh พลาด ก็โชว์ของเดิมไว้
  RecipeLibraryState _toLibraryState(PurchasedRecipesState state) {
    return switch (state.status) {
      PurchasedRecipesStatus.ready => RecipeLibraryLoaded(state.recipes),
      _ when state.recipes.isNotEmpty => RecipeLibraryLoaded(state.recipes),
      PurchasedRecipesStatus.failure => RecipeLibraryFailure(
        state.error ?? 'Could not load purchased recipes.',
      ),
      _ => const RecipeLibraryLoading(),
    };
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
          _collectionType.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<PurchasedRecipesBloc, PurchasedRecipesState>(
        builder: (context, state) => RecipeCollectionBody(
          state: _toLibraryState(state),
          emptyMessage: _collectionType.emptyMessage,
          onRefresh: () => _refresh(context),
          onRetry: () => context.read<PurchasedRecipesBloc>().add(
            const PurchasedRecipesRequested(),
          ),
        ),
      ),
    );
  }
}
