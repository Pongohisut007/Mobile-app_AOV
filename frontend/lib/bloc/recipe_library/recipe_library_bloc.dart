import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// อ่าน userId + token จาก secure storage เองแบบเดียวกับ ProfileBloc
class RecipeLibraryBloc extends Bloc<RecipeLibraryEvent, RecipeLibraryState> {
  RecipeLibraryBloc(
    this._repository, {
    required this.collectionType,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       super(const RecipeLibraryInitial()) {
    on<RecipeLibraryRequested>(_load);
    on<RecipeLibraryRefreshRequested>(_load);
    on<RecipeLibraryMoreRequested>(_loadMore);
  }

  final RecipeLibraryRepository _repository;
  final TokenStorage _tokenStorage;
  final RecipeCollectionType collectionType;

  // รายการที่เคยโหลดแล้ว เก็บใน RAM ข้ามการเปิด/ปิดหน้า (key = user + ประเภทคลัง)
  // เปิดหน้าซ้ำจะโชว์ของเดิมทันที แล้วโหลดของใหม่มาแทนเงียบ ๆ
  static final Map<String, _CachedCollection> _cache = {};

  /// เปลี่ยนบัญชี (login/logout) ต้องล้าง
  static void clearCache() => _cache.clear();

  String _cacheKey(String userId) => '$userId:${collectionType.name}';

  // หน้าที่โหลดมาแล้ว และรอบการโหลดล่าสุด (กันหน้าถัดไปของรอบเก่ามาต่อท้ายรอบใหม่)
  int _page = 0;
  int _generation = 0;

  Future<void> _load(
    RecipeLibraryEvent event,
    Emitter<RecipeLibraryState> emit,
  ) async {
    final generation = ++_generation;
    final accessToken = await _tokenStorage.readAccessToken();
    final userId = await _tokenStorage.readUserId();

    if (accessToken == null || userId == null) {
      emit(const RecipeLibraryFailure('Please sign in to see your recipes.'));
      return;
    }

    final cached = _cache[_cacheKey(userId)];
    if (event is RecipeLibraryRequested && cached != null) {
      // มีของเดิมใน RAM: โชว์เลย ไม่ขึ้นตัวหมุน
      _page = cached.page;
      emit(cached.state);
    } else if (event is RecipeLibraryRequested ||
        state is! RecipeLibraryLoaded) {
      emit(const RecipeLibraryLoading());
    }

    try {
      final result = await _repository.fetchCollectionPage(
        collectionType,
        userId: userId,
        accessToken: accessToken,
      );
      if (generation != _generation) return;
      _page = result.page;
      _emitLoaded(
        emit,
        userId,
        RecipeLibraryLoaded(result.items, hasMore: result.hasMore),
      );
    } on Exception catch (error) {
      if (generation != _generation) return;
      // โหลดเบื้องหลังพลาดแต่มีของเดิมโชว์อยู่ ก็ปล่อยของเดิมไว้
      if (cached != null && state is RecipeLibraryLoaded) return;
      emit(RecipeLibraryFailure(error.toString()));
    }
  }

  // เก็บลง RAM ทุกครั้งที่รายการเปลี่ยน (ไม่เก็บสถานะกำลังโหลด/error ของหน้าถัดไป)
  void _emitLoaded(
    Emitter<RecipeLibraryState> emit,
    String userId,
    RecipeLibraryLoaded loaded,
  ) {
    _cache[_cacheKey(userId)] = _CachedCollection(
      RecipeLibraryLoaded(loaded.recipes, hasMore: loaded.hasMore),
      _page,
    );
    emit(loaded);
  }

  Future<void> _loadMore(
    RecipeLibraryMoreRequested event,
    Emitter<RecipeLibraryState> emit,
  ) async {
    final current = state;
    if (current is! RecipeLibraryLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    final generation = _generation;
    final accessToken = await _tokenStorage.readAccessToken();
    final userId = await _tokenStorage.readUserId();
    if (accessToken == null || userId == null) return;

    emit(
      RecipeLibraryLoaded(
        current.recipes,
        hasMore: current.hasMore,
        isLoadingMore: true,
      ),
    );

    try {
      final result = await _repository.fetchCollectionPage(
        collectionType,
        userId: userId,
        accessToken: accessToken,
        page: _page + 1,
      );
      if (generation != _generation) return;
      _page = result.page;

      // กันสูตรซ้ำถ้ามีรายการใหม่เข้ามาระหว่างเลื่อน (ลำดับเลื่อนไป 1 ช่อง)
      final seenIds = {for (final recipe in current.recipes) recipe.id};
      _emitLoaded(
        emit,
        userId,
        RecipeLibraryLoaded([
          ...current.recipes,
          ...result.items.where((recipe) => seenIds.add(recipe.id)),
        ], hasMore: result.hasMore),
      );
    } on Exception catch (error) {
      if (generation != _generation) return;
      emit(
        RecipeLibraryLoaded(
          current.recipes,
          hasMore: current.hasMore,
          loadMoreError: error.toString(),
        ),
      );
    }
  }
}

class _CachedCollection {
  const _CachedCollection(this.state, this.page);

  final RecipeLibraryLoaded state;
  final int page;
}
