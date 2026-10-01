import 'package:flutter_application_1/bloc/banner_rating/banner_rating_event.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_state.dart';
import 'package:flutter_application_1/repositories/banner_rating_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// คะแนนดาวของ event หนึ่งรายการ สร้างใหม่ทุกครั้งที่เปิดหน้า Event
class BannerRatingBloc extends Bloc<BannerRatingEvent, BannerRatingState> {
  BannerRatingBloc(
    this._repository, {
    required this.bannerId,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       super(const BannerRatingState()) {
    on<BannerRatingRequested>(_onRequested);
    on<BannerRatingSubmitted>(_onSubmitted);
  }

  final BannerRatingRepository _repository;
  final TokenStorage _tokenStorage;
  final String bannerId;

  Future<String?> _readAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return null;
    return accessToken;
  }

  Future<void> _onRequested(
    BannerRatingRequested event,
    Emitter<BannerRatingState> emit,
  ) async {
    emit(state.copyWith(status: BannerRatingStatus.loading, clearError: true));

    try {
      final accessToken = await _readAccessToken();
      final summary = await _repository.fetchSummary(bannerId);
      final myRating = accessToken == null
          ? null
          : await _repository.fetchMyRating(accessToken, bannerId);

      emit(
        BannerRatingState(
          status: BannerRatingStatus.ready,
          summary: summary,
          myRating: myRating,
          isLoggedIn: accessToken != null,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: BannerRatingStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    BannerRatingSubmitted event,
    Emitter<BannerRatingState> emit,
  ) async {
    if (state.isSubmitting) return;

    final accessToken = await _readAccessToken();
    if (accessToken == null) {
      emit(state.copyWith(isLoggedIn: false));
      return;
    }

    emit(
      state.copyWith(
        submitStatus: BannerRatingSubmitStatus.submitting,
        clearError: true,
      ),
    );

    try {
      final myRating = await _repository.rate(
        accessToken,
        bannerId,
        rating: event.rating,
        comment: event.comment,
      );
      // โหลดคะแนนเฉลี่ยใหม่ให้รวมคะแนนที่เพิ่งให้ไป
      final summary = await _repository.fetchSummary(bannerId);

      emit(
        state.copyWith(
          summary: summary,
          myRating: myRating,
          submitStatus: BannerRatingSubmitStatus.success,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          submitStatus: BannerRatingSubmitStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
