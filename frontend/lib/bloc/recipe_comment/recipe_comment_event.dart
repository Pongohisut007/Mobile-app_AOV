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