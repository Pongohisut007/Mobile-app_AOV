import 'package:flutter_application_1/models/banner_rating.dart';

enum BannerRatingStatus { loading, ready, failure }

enum BannerRatingSubmitStatus { idle, submitting, success, failure }

class BannerRatingState {
  const BannerRatingState({
    this.status = BannerRatingStatus.loading,
    this.summary = const BannerRatingSummary(),
    this.myRating,
    this.isLoggedIn = false,
    this.submitStatus = BannerRatingSubmitStatus.idle,
    this.error,
  });

  final BannerRatingStatus status;
  final BannerRatingSummary summary;

  /// คะแนนที่เราเคยให้ไว้ ใช้เติมดาวกับช่องความคิดเห็นตอนเปิดหน้า
  final BannerRating? myRating;

  final bool isLoggedIn;
  final BannerRatingSubmitStatus submitStatus;
  final String? error;

  bool get isSubmitting => submitStatus == BannerRatingSubmitStatus.submitting;

  BannerRatingState copyWith({
    BannerRatingStatus? status,
    BannerRatingSummary? summary,
    BannerRating? myRating,
    bool? isLoggedIn,
    BannerRatingSubmitStatus? submitStatus,
    String? error,
    bool clearError = false,
  }) {
    return BannerRatingState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      myRating: myRating ?? this.myRating,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      submitStatus: submitStatus ?? this.submitStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
