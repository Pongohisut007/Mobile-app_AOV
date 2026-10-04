import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';

typedef _PageLoader = Future<PagedResult<Food>> Function(int page);

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;

  //system search
  // กันผลลัพธ์ของ request เก่ามาทับ request ล่าสุด
  // เช่น ผู้ใช้พิมพ์ค้นหาแล้วกดล้างทันที ทั้งสอง request วิ่งพร้อมกัน
  int _requestId = 0;

  // วิธีโหลดของรายการล่าสุด กับหน้าที่โหลดมาแล้ว ใช้ตอนขอหน้าถัดไป
  _PageLoader? _loader;
  int _page = 0;

  FoodBloc(this.repository) : super(FoodInitial()) {
    on<FetchFoodEvent>(_onFetchFoodEvent);
    on<FetchFoodByCategoryEvent>(_onFetchFoodByCategoryEvent);
    on<FetchCommunityFoodsByCategoryEvent>(_onFetchCommunityFoodsByCategoryEvent);
    on<SearchFoodEvent>(_onSearchFoodEvent);
    on<FoodLoadMoreRequested>(_onLoadMore);
    on<FoodSilentRefreshRequested>(_onSilentRefresh);
    on<FoodRemoved>(_onRemoved);
  }

  void _onRemoved(FoodRemoved event, Emitter<FoodState> emit) {
    final current = state;
    if (current is! FoodLoaded) return;
    emit(
      current.copyWith(
        foods: current.foods
            .where((food) => food.idfoods != event.foodId)
            .toList(growable: false),
      ),
    );
  }

  bool _isSilentRefreshing = false;

  Future<void> _onSilentRefresh(
    FoodSilentRefreshRequested event,
    Emitter<FoodState> emit,
  ) async {
    final loader = _loader;
    // ยังโหลดครั้งแรกไม่เสร็จ/error อยู่ ไม่ต้องอัปเดตเงียบ ๆ
    if (state is! FoodLoaded || loader == null || _isSilentRefreshing) return;

    final requestId = _requestId;
    _isSilentRefreshing = true;
    try {
      final result = await loader(1);
      // ระหว่างรอมีการโหลดรายการใหม่ (เปลี่ยนหมวด/ค้นหา) ผลนี้ไม่ใช้แล้ว
      if (requestId != _requestId || state is! FoodLoaded) return;
      final current = state as FoodLoaded;

      // แทนแค่ส่วนหน้าแรกด้วยของใหม่ ส่วนที่เลื่อนโหลดเพิ่มไว้แล้วคงไว้
      // รายการจะได้ไม่หดจนตำแหน่งที่เลื่อนอยู่กระโดด
      final freshIds = {for (final food in result.items) food.idfoods};
      final rest = current.foods
          .skip(FoodRepository.pageSize)
          .where((food) => !freshIds.contains(food.idfoods));
      final loadedMorePages = _page > 1;
      if (!loadedMorePages) _page = result.page;

      emit(
        current.copyWith(
          foods: [...result.items, ...rest],
          hasMore: loadedMorePages ? current.hasMore : result.hasMore,
        ),
      );
    } catch (_) {
      // เงียบไว้ รายการเดิมยังแสดงอยู่
    } finally {
      _isSilentRefreshing = false;
    }
  }

  Future<void> _onFetchFoodEvent(
    FetchFoodEvent event,
    Emitter<FoodState> emit,
  ) {
    return _loadFirstPage(
      emit,
      (page) => repository.fetchRecipesPage(page: page),
    );
  }

  Future<void> _onFetchFoodByCategoryEvent(
    FetchFoodByCategoryEvent event,
    Emitter<FoodState> emit,
  ) {
    // ไม่ได้เลือก category (ค่าว่าง) = ทุกหมวด
    return _loadFirstPage(
      emit,
      (page) => repository.fetchRecipesPage(
        type: 'official',
        categoryId: event.categoryId,
        page: page,
      ),
    );
  }

  Future<void> _onFetchCommunityFoodsByCategoryEvent(
    FetchCommunityFoodsByCategoryEvent event,
    Emitter<FoodState> emit,
  ) {
    // community แสดงเฉพาะสูตรที่เผยแพร่แล้ว ไม่ได้เลือก category = ทุกหมวด
    return _loadFirstPage(
      emit,
      (page) => repository.fetchRecipesPage(
        type: 'community',
        status: 'published',
        categoryId: event.categoryId,
        page: page,
      ),
    );
  }

  Future<void> _onSearchFoodEvent(
    SearchFoodEvent event,
    Emitter<FoodState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    // หน้า home แสดงเฉพาะสูตร official จึงค้นหาในขอบเขตเดียวกัน
    // และถ้าเลือกหมวดอยู่ ต้องค้นหาเฉพาะในหมวดนั้น
    return _loadFirstPage(
      emit,
      (page) => repository.searchFoods(
        query,
        type: event.type,
        categoryId: event.categoryId.isEmpty ? null : event.categoryId,
        // community แสดงเฉพาะสูตรที่เผยแพร่แล้ว
        status: event.type == 'community' ? 'published' : null,
        page: page,
      ),
      query: query,
    );
  }

  Future<void> _loadFirstPage(
    Emitter<FoodState> emit,
    _PageLoader loader, {
    String? query,
  }) async {
    final requestId = ++_requestId;
    _loader = loader;
    _page = 0;
    emit(FoodLoading());
    try {
      final result = await loader(1);
      if (requestId != _requestId) return;
      _page = result.page;
      emit(FoodLoaded(result.items, query: query, hasMore: result.hasMore));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FoodError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    FoodLoadMoreRequested event,
    Emitter<FoodState> emit,
  ) async {
    final current = state;
    final loader = _loader;
    if (current is! FoodLoaded ||
        loader == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    final requestId = _requestId;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    try {
      final result = await loader(_page + 1);
      // ระหว่างรอมีการโหลดรายการใหม่ (เปลี่ยนหมวด/ค้นหา) หน้านี้ไม่ใช้แล้ว
      if (requestId != _requestId) return;
      _page = result.page;

      // กันสูตรซ้ำถ้ามีสูตรใหม่ถูกเผยแพร่ระหว่างเลื่อน (ลำดับเลื่อนไป 1 ช่อง)
      final loaded = state as FoodLoaded;
      final seenIds = {for (final food in loaded.foods) food.idfoods};
      final newFoods = result.items.where((food) => seenIds.add(food.idfoods));

      emit(
        loaded.copyWith(
          foods: [...loaded.foods, ...newFoods],
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        (state as FoodLoaded).copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ),
      );
    }
  }
}
