import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_state.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/repositories/recipe_comment_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipeCommentBloc extends Bloc<RecipeCommentEvent, RecipeCommentState> {
  RecipeCommentBloc(
    this._repository, {
    required this.recipeId,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       super(const RecipeCommentState()) {
    on<RecipeCommentsRequested>(_onRequested);
    on<RecipeCommentsMoreRequested>(_onMoreRequested);
    on<RecipeCommentSubmitted>(_onSubmitted);
    on<RecipeCommentUpdated>(_onUpdated);
    on<RecipeCommentDeleted>(_onDeleted);
  }

  static const _pageSize = 3;

  final RecipeCommentRepository _repository;
  final TokenStorage _tokenStorage;
  final String recipeId;

  Future<String?> _readAccessToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Future<void> _onRequested(
    RecipeCommentsRequested event,
    Emitter<RecipeCommentState> emit,
  ) async {
    emit(state.copyWith(status: RecipeCommentStatus.loading, clearError: true));
    try {
      final token = await _readAccessToken();
      final userId = token == null ? null : await _tokenStorage.readUserId();
      final page = await _repository.fetchComments(recipeId, limit: _pageSize);
      final permission = token == null
          ? null
          : await _repository.fetchPermission(token, recipeId);
      emit(
        RecipeCommentState(
          status: RecipeCommentStatus.ready,
          comments: page.items,
          total: page.total,
          page: page.page,
          limit: page.limit,
          isLoggedIn: token != null,
          canComment: permission?.canComment ?? false,
          userAvatarUrl: permission?.userAvatarUrl,
          userId: userId,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: RecipeCommentStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onMoreRequested(
    RecipeCommentsMoreRequested event,
    Emitter<RecipeCommentState> emit,
  ) async {
    if (state.status != RecipeCommentStatus.ready ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final visibleLimit = (state.page * state.limit).clamp(0, state.total);
      final needsRefill = state.comments.length < visibleLimit;
      final targetCount = needsRefill
          ? visibleLimit
          : ((state.page + 1) * state.limit).clamp(0, state.total);
      final comments = needsRefill ? <RecipeComment>[] : [...state.comments];
      var pageNumber = needsRefill ? 0 : state.page;
      RecipeCommentPage? result;

      while (comments.length < targetCount) {
        result = await _repository.fetchComments(
          recipeId,
          page: pageNumber + 1,
          limit: state.limit,
        );
        if (result.items.isEmpty) break;
        comments.addAll(result.items);
        pageNumber = result.page;
      }

      emit(
        state.copyWith(
          comments: comments,
          total: result?.total ?? state.total,
          page: result?.page ?? pageNumber,
          limit: result?.limit ?? state.limit,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (error) {
      emit(state.copyWith(isLoadingMore: false, error: error.toString()));
    }
  }

  Future<void> _onSubmitted(
    RecipeCommentSubmitted event,
    Emitter<RecipeCommentState> emit,
  ) async {
    if (state.isSubmitting) return;
    final token = await _readAccessToken();
    if (token == null) {
      emit(state.copyWith(isLoggedIn: false, canComment: false));
      return;
    }

    emit(
      state.copyWith(
        submitStatus: RecipeCommentSubmitStatus.submitting,
        mutationType: RecipeCommentMutationType.submit,
        clearError: true,
      ),
    );
    try {
      final comment = await _repository.addComment(
        token,
        recipeId,
        event.comment,
      );
      final comments = [
        comment,
        ...state.comments,
      ].take(_pageSize).toList(growable: false);
      emit(
        state.copyWith(
          comments: comments,
          total: state.total + 1,
          page: 1,
          limit: _pageSize,
          submitStatus: RecipeCommentSubmitStatus.success,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          submitStatus: RecipeCommentSubmitStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdated(
    RecipeCommentUpdated event,
    Emitter<RecipeCommentState> emit,
  ) async {
    if (state.mutationStatus == RecipeCommentMutationStatus.loading) return;
    final text = event.comment.trim();
    if (text.isEmpty) {
      emit(
        state.copyWith(
          mutationStatus: RecipeCommentMutationStatus.failure,
          error: 'ความคิดเห็นต้องไม่ว่าง',
        ),
      );
      return;
    }

    final token = await _readAccessToken();
    if (token == null) {
      emit(
        state.copyWith(
          mutationStatus: RecipeCommentMutationStatus.failure,
          error: 'กรุณาเข้าสู่ระบบอีกครั้ง',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        mutationStatus: RecipeCommentMutationStatus.loading,
        mutationType: RecipeCommentMutationType.edit,
        clearError: true,
      ),
    );
    try {
      final updated = await _repository.updateComment(
        token,
        recipeId,
        event.commentId,
        text,
      );
      emit(
        state.copyWith(
          comments: state.comments
              .map((comment) => comment.id == updated.id ? updated : comment)
              .toList(growable: false),
          mutationStatus: RecipeCommentMutationStatus.success,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          mutationStatus: RecipeCommentMutationStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleted(
    RecipeCommentDeleted event,
    Emitter<RecipeCommentState> emit,
  ) async {
    if (state.mutationStatus == RecipeCommentMutationStatus.loading) return;
    final token = await _readAccessToken();
    if (token == null) {
      emit(
        state.copyWith(
          mutationStatus: RecipeCommentMutationStatus.failure,
          error: 'กรุณาเข้าสู่ระบบอีกครั้ง',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        mutationStatus: RecipeCommentMutationStatus.loading,
        clearError: true,
      ),
    );
    try {
      await _repository.deleteComment(token, recipeId, event.commentId);
      final totalAfterDelete = (state.total - 1).clamp(0, 0x7fffffff);
      final targetCount = (state.page * state.limit).clamp(0, totalAfterDelete);
      final comments = <RecipeComment>[];
      var pageNumber = 0;
      var refreshedTotal = totalAfterDelete;
      var refreshedLimit = state.limit;

      try {
        while (comments.length < targetCount) {
          final page = await _repository.fetchComments(
            recipeId,
            page: pageNumber + 1,
            limit: state.limit,
          );
          if (page.items.isEmpty) break;
          comments.addAll(page.items);
          pageNumber = page.page;
          refreshedTotal = page.total;
          refreshedLimit = page.limit;
        }
      } on Exception catch (error) {
        emit(
          state.copyWith(
            comments: state.comments
                .where((comment) => comment.id != event.commentId)
                .toList(growable: false),
            total: totalAfterDelete,
            mutationStatus: RecipeCommentMutationStatus.success,
            mutationType: RecipeCommentMutationType.delete,
            error: error.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          comments: comments,
          total: refreshedTotal,
          page: pageNumber,
          limit: refreshedLimit,
          mutationStatus: RecipeCommentMutationStatus.success,
          mutationType: RecipeCommentMutationType.delete,
          clearError: true,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          mutationStatus: RecipeCommentMutationStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
