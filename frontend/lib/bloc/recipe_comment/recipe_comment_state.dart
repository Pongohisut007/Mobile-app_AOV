import 'package:flutter_application_1/models/recipe_comment.dart';

enum RecipeCommentStatus { loading, ready, failure }

enum RecipeCommentSubmitStatus { idle, submitting, success, failure }

enum RecipeCommentMutationStatus { idle, loading, success, failure }

enum RecipeCommentMutationType { submit, edit, delete }

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
    this.mutationStatus = RecipeCommentMutationStatus.idle,
    this.mutationType,
    this.mutatingCommentId,
    this.userId,
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
  final RecipeCommentMutationStatus mutationStatus;
  final RecipeCommentMutationType? mutationType;

  /// คอมเมนต์ที่กำลังแก้ไข/ลบอยู่ ใช้แสดงตัวหมุนบนการ์ดนั้น
  final String? mutatingCommentId;
  final String? userId;
  final String? error;

  bool get hasMore => comments.length < total;
  bool get isSubmitting => submitStatus == RecipeCommentSubmitStatus.submitting;
  bool get isMutating => mutationStatus == RecipeCommentMutationStatus.loading;

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
    RecipeCommentMutationStatus? mutationStatus,
    RecipeCommentMutationType? mutationType,
    String? mutatingCommentId,
    bool clearMutatingCommentId = false,
    String? userId,
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
      mutationStatus: mutationStatus ?? this.mutationStatus,
      mutationType: mutationType ?? this.mutationType,
      mutatingCommentId: clearMutatingCommentId
          ? null
          : (mutatingCommentId ?? this.mutatingCommentId),
      userId: userId ?? this.userId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
