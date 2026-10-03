import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// โหลดสูตรที่ซื้อแล้วครั้งเดียวแล้วเก็บไว้ทั้งแอป หน้าอื่นอ่านจากที่นี่แทนการยิง API เอง
/// อ่าน token จาก secure storage เองแบบเดียวกับ FavoriteBloc
/// storage ไม่มี stream บอกว่าค่าเปลี่ยน หน้า login/logout จึงต้องสั่ง
/// PurchasedRecipesRequested เองหลังเขียน/ลบ token
class PurchasedRecipesBloc
    extends Bloc<PurchasedRecipesEvent, PurchasedRecipesState> {
  PurchasedRecipesBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(PurchasedRecipesState()) {
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
      emit(PurchasedRecipesState(status: PurchasedRecipesStatus.ready));
      return;
    }

    emit(
      PurchasedRecipesState(
        status: PurchasedRecipesStatus.loading,
        recipes: keepCurrent ? state.recipes : const [],
      ),
    );

    try {
      final recipes = await _repository.fetchCollection(
        RecipeCollectionType.purchased,
        userId: userId,
        accessToken: accessToken,
      );
      emit(
        PurchasedRecipesState(
          status: PurchasedRecipesStatus.ready,
          recipes: recipes,
        ),
      );
    } on Exception catch (error) {
      emit(
        PurchasedRecipesState(
          status: PurchasedRecipesStatus.failure,
          recipes: state.recipes,
          error: error.toString(),
        ),
      );
    }
  }
}
