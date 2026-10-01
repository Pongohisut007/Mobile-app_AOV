import 'package:flutter_application_1/bloc/recipe_review/recipe_review_event.dart';
import 'package:flutter_application_1/bloc/recipe_review/recipe_review_state.dart';
import 'package:flutter_application_1/repositories/recipe_review_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// คะแนนดาวของสูตรอาหารหนึ่งสูตร สร้างใหม่ทุกครั้งที่เปิดหน้ารายละเอียดสูตร
class RecipeReviewBloc extends Bloc<RecipeReviewEvent, RecipeReviewState> {
  RecipeReviewBloc(
    this._repository, {
    required this.recipeId,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       super(const RecipeReviewState()) {
    on<RecipeReviewRequested>(_onRequested);
    on<RecipeReviewSubmitted>(_onSubmitted);
  }

  final RecipeReviewRepository _repository;
  final TokenStorage _tokenStorage;
  final String recipeId;

  Future<String?> _readAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return null;
    return accessToken;
  }

  Future<void> _onRequested(
    RecipeReviewRequested event,
    Emitter<RecipeReviewState> emit,
  ) async {
    emit(state.copyWith(status: RecipeReviewStatus.loading, clearError: true));

    try {
      final accessToken = await _readAccessToken();
      final summary = await _repository.fetchSummary(recipeId);
      final mine = accessToken == null
          ? null
          : await _repository.fetchMyReview(accessToken, recipeId);

      emit(
        RecipeReviewState(
          status: RecipeReviewStatus.ready,
          summary: summary,
          myReview: mine?.review,
          isLoggedIn: accessToken != null,
          canReview: mine?.canReview ?? false,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: RecipeReviewStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    RecipeReviewSubmitted event,
    Emitter<RecipeReviewState> emit,
  ) async {
    if (state.isSubmitting) return;

    final accessToken = await _readAccessToken();
    if (accessToken == null) {
      emit(state.copyWith(isLoggedIn: false, canReview: false));
      return;
    }

    emit(
      state.copyWith(
        submitStatus: RecipeReviewSubmitStatus.submitting,
        clearError: true,
      ),
    );

    try {
      final myReview = await _repository.submitReview(
        accessToken,
        recipeId,
        rating: event.rating,
        comment: event.comment,
        tags: event.tags,
      );
      // โหลดคะแนนเฉลี่ยใหม่ให้รวมคะแนนที่เพิ่งให้ไป
      final summary = await _repository.fetchSummary(recipeId);

      emit(
        state.copyWith(
          summary: summary,
          myReview: myReview,
          submitStatus: RecipeReviewSubmitStatus.success,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          submitStatus: RecipeReviewSubmitStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
