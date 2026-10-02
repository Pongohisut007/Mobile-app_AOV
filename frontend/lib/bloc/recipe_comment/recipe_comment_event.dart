sealed class RecipeCommentEvent {
  const RecipeCommentEvent();
}

final class RecipeCommentsRequested extends RecipeCommentEvent {
  const RecipeCommentsRequested();
}

final class RecipeCommentsMoreRequested extends RecipeCommentEvent {
  const RecipeCommentsMoreRequested();
}

final class RecipeCommentSubmitted extends RecipeCommentEvent {
  const RecipeCommentSubmitted(this.comment);

  final String comment;
}

final class RecipeCommentUpdated extends RecipeCommentEvent {
  const RecipeCommentUpdated(this.commentId, this.comment);

  final String commentId;
  final String comment;
}

final class RecipeCommentDeleted extends RecipeCommentEvent {
  const RecipeCommentDeleted(this.commentId);

  final String commentId;
}
