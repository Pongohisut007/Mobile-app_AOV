import 'package:flutter_application_1/models/recipe_comment.dart';

enum RecipeCommentStatus { loading, ready, failure }

enum RecipeCommentSubmitStatus { idle, submitting, success, failure }

class RecipeCommentState {
  const RecipeCommentState({
    this.status = RecipeCommentStatus.loading,
    this.comments = const [],
    this.total = 0,
    this.page = 0,
    this.limit = 3,
    this.isLoggedIn = false,
    this.canComment = false,
    this.userAvatarUrl,
    this.isLoadingMore = false,
    this.submitStatus = RecipeCommentSubmitStatus.idle,
    this.error,
  });

  final RecipeCommentStatus status;
  final List<RecipeComment> comments;
  final int total;
  final int page;
  final int limit;
  final bool isLoggedIn;
  final bool canComment;
  final String? userAvatarUrl;
  final bool isLoadingMore;
  final RecipeCommentSubmitStatus submitStatus;
  final String? error;

  bool get hasMore => page * limit < total;
  bool get isSubmitting =>
      submitStatus == RecipeCommentSubmitStatus.submitting;

  RecipeCommentState copyWith({
    RecipeCommentStatus? status,
    List<RecipeComment>? comments,
    int? total,
    int? page,
    int? limit,
    bool? isLoggedIn,
    bool? canComment,
    String? userAvatarUrl,
    bool? isLoadingMore,
    RecipeCommentSubmitStatus? submitStatus,
    String? error,
    bool clearError = false,
  }) {
    return RecipeCommentState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      canComment: canComment ?? this.canComment,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      submitStatus: submitStatus ?? this.submitStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }
}