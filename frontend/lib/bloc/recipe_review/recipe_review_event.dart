sealed class RecipeReviewEvent {
  const RecipeReviewEvent();
}

/// โหลดคะแนนเฉลี่ย รีวิว และรีวิวของเราเอง (ถ้าล็อกอินอยู่)
final class RecipeReviewRequested extends RecipeReviewEvent {
  const RecipeReviewRequested();
}

/// กดส่งคะแนนดาว + ชิป + ความคิดเห็น
final class RecipeReviewSubmitted extends RecipeReviewEvent {
  const RecipeReviewSubmitted({
    required this.rating,
    this.comment = '',
    this.tags = const [],
  });

  final int rating;
  final String comment;
  final List<String> tags;
}
