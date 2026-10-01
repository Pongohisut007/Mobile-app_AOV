import 'package:flutter_application_1/models/recipe_review.dart';

enum RecipeReviewStatus { loading, ready, failure }

enum RecipeReviewSubmitStatus { idle, submitting, success, failure }

class RecipeReviewState {
  const RecipeReviewState({
    this.status = RecipeReviewStatus.loading,
    this.summary = const RecipeReviewSummary(),
    this.myReview,
    this.isLoggedIn = false,
    this.canReview = false,
    this.submitStatus = RecipeReviewSubmitStatus.idle,
    this.error,
  });

  final RecipeReviewStatus status;
  final RecipeReviewSummary summary;

  /// รีวิวที่เราเคยให้ไว้ ใช้เติมดาวกับช่องความคิดเห็นตอนเปิดหน้า
  final RecipeReview? myReview;

  final bool isLoggedIn;

  /// ซื้อสูตรนี้แล้วหรือยัง ยังไม่ซื้อ = ดูได้อย่างเดียว
  final bool canReview;

  final RecipeReviewSubmitStatus submitStatus;
  final String? error;

  bool get isSubmitting => submitStatus == RecipeReviewSubmitStatus.submitting;

  RecipeReviewState copyWith({
    RecipeReviewStatus? status,
    RecipeReviewSummary? summary,
    RecipeReview? myReview,
    bool? isLoggedIn,
    bool? canReview,
    RecipeReviewSubmitStatus? submitStatus,
    String? error,
    bool clearError = false,
  }) {
    return RecipeReviewState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      myReview: myReview ?? this.myReview,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      canReview: canReview ?? this.canReview,
      submitStatus: submitStatus ?? this.submitStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
