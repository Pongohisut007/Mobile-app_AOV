sealed class BannerRatingEvent {
  const BannerRatingEvent();
}

/// โหลดคะแนนเฉลี่ย ความคิดเห็น และคะแนนของเราเอง (ถ้าล็อกอินอยู่)
final class BannerRatingRequested extends BannerRatingEvent {
  const BannerRatingRequested();
}

/// กดส่งคะแนนดาว + ความคิดเห็น
final class BannerRatingSubmitted extends BannerRatingEvent {
  const BannerRatingSubmitted({required this.rating, this.comment = ''});

  final int rating;
  final String comment;
}
