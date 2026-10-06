import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/api_cache.dart';

/// โหลด id ของสูตรที่ซื้อแล้วครั้งเดียวแล้วเก็บไว้ทั้งแอป หน้าอื่นอ่านจากที่นี่แทนการยิง API เอง
/// อ่าน token จาก secure storage เองแบบเดียวกับ FavoriteBloc
/// storage ไม่มี stream บอกว่าค่าเปลี่ยน หน้า login/logout จึงต้องสั่ง
/// PurchasedRecipesRequested เองหลังเขียน/ลบ token
class PurchasedRecipesBloc
    extends Bloc<PurchasedRecipesEvent, PurchasedRecipesState> {
  PurchasedRecipesBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const PurchasedRecipesState()) {
    on<PurchasedRecipesRequested>(_onRequested);
    on<PurchasedRecipesRefreshed>(_onRefreshed);
  }

  final RecipeLibraryRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _onRequested(
    PurchasedRecipesRequested event,
    Emitter<PurchasedRecipesState> emit,
  ) async {
    // เริ่มจาก state เปล่าเสมอ กันสิทธิ์ของบัญชีก่อนหน้าติดมา
    await _load(emit, keepCurrent: false);
  }

  Future<void> _onRefreshed(
    PurchasedRecipesRefreshed event,
    Emitter<PurchasedRecipesState> emit,
  ) async {
    await _load(emit, keepCurrent: true);
  }

  static const _cacheKey = '${ApiCache.userPrefix}purchased-ids';

  static Future<Set<String>?> _readCachedIds() async {
    final body = await ApiCache.instance.read(_cacheKey);
    if (body == null) return null;
    try {
      return {...(jsonDecode(body) as List).whereType<String>()};
    } on Object {
      return null;
    }
  }

  Future<void> _load(
    Emitter<PurchasedRecipesState> emit, {
    required bool keepCurrent,
  }) async {
    final accessToken = await _tokenStorage.readAccessToken();
    final userId = await _tokenStorage.readUserId();

    // ยังไม่ล็อกอิน หรือเพิ่ง logout สูตรของคนก่อนหน้าต้องไม่ค้าง
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        userId == null ||
        userId.trim().isEmpty) {
      emit(const PurchasedRecipesState(status: PurchasedRecipesStatus.ready));
      return;
    }

    // เปิดแอปใหม่: ใช้รายการที่เคยโหลดไว้ไปก่อน ปุ่มซื้อ/เริ่มทำอาหารจะได้ขึ้นทันที
    // (ระหว่างนั้นถามของใหม่ ซื้อเพิ่มจากเครื่องอื่นก็จะอัปเดตตาม)
    if (!keepCurrent) {
      final cached = await _readCachedIds();
      if (cached != null) {
        emit(
          PurchasedRecipesState(
            status: PurchasedRecipesStatus.ready,
            recipeIds: cached,
          ),
        );
      }
    }
    if (state.status != PurchasedRecipesStatus.ready || keepCurrent) {
      emit(
        PurchasedRecipesState(
          status: PurchasedRecipesStatus.loading,
          recipeIds: keepCurrent ? state.recipeIds : const {},
        ),
      );
    }

    try {
      final recipeIds = await _repository.fetchPurchasedRecipeIds(
        userId: userId,
        accessToken: accessToken,
      );
      unawaited(
        ApiCache.instance.write(_cacheKey, jsonEncode(recipeIds.toList())),
      );
      emit(
        PurchasedRecipesState(
          status: PurchasedRecipesStatus.ready,
          recipeIds: recipeIds,
        ),
      );
    } on Exception catch (error) {
      emit(
        PurchasedRecipesState(
          status: PurchasedRecipesStatus.failure,
          recipeIds: state.recipeIds,
          error: error.toString(),
        ),
      );
    }
  }
}
