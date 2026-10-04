import 'package:flutter_application_1/models/food.dart';

abstract class FoodState {
  FoodState();
}

class FoodInitial extends FoodState {
  //Constructor
  FoodInitial();
}

class FoodLoading extends FoodState {
  //Constructor
  FoodLoading();
}

class FoodLoaded extends FoodState {
  /// สูตรทุกหน้าที่โหลดมาแล้ว ต่อกันตามลำดับ
  final List<Food> foods;
  // คำค้นหาที่ทำให้ได้ผลลัพธ์ชุดนี้ ถ้าเป็น null คือไม่ได้มาจากการค้นหา
  final String? query;

  /// backend ยังมีหน้าถัดไปให้โหลด
  final bool hasMore;

  /// กำลังโหลดหน้าถัดไป (รายการเดิมยังแสดงอยู่)
  final bool isLoadingMore;

  /// โหลดหน้าถัดไปไม่สำเร็จ (รายการเดิมยังอยู่ ลองใหม่ได้)
  final String? loadMoreError;

  FoodLoaded(
    this.foods, {
    this.query,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  FoodLoaded copyWith({
    List<Food>? foods,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return FoodLoaded(
      foods ?? this.foods,
      query: query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

class FoodError extends FoodState {
  final String message;
  FoodError({required this.message});
}
