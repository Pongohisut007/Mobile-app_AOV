import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/user_cache.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const ProfileInitial()) {
    on<ProfileRequested>(_loadProfile);
    on<ProfileRefreshRequested>(_loadProfile);
    on<ProfileUpdated>((event, emit) => emit(ProfileLoaded(event.profile)));
  }

  final ProfileRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _loadProfile(
    ProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      emit(const ProfileGuest());
      return;
    }

    // เปิดครั้งแรก: มีโปรไฟล์เก่าในเครื่อง = โชว์ทันที แล้วค่อยแทนด้วยของใหม่
    var showingCache = state is ProfileLoaded;
    if (event is ProfileRequested && !showingCache) {
      final cached = await _repository.cachedProfile();
      showingCache = cached != null;
      emit(cached != null ? ProfileLoaded(cached) : const ProfileLoading());
    } else if (!showingCache) {
      emit(const ProfileLoading());
    }
    try {
      final profile = await _repository.fetchProfile(accessToken);
      emit(ProfileLoaded(profile));
    } on ProfileRepositoryException catch (error) {
      if (error.sessionExpired) {
        // token ใช้ไม่ได้แล้ว: ล้างทิ้งแล้วกลับเป็นผู้เยี่ยมชม จะได้มีปุ่มเข้าสู่ระบบ
        // (ถ้าค้าง token ไว้ หน้าโปรไฟล์จะ error วนไปเรื่อย ๆ จน login ใหม่ไม่ได้)
        await _tokenStorage.clearSession();
        clearUserCaches();
        emit(const ProfileGuest(sessionExpired: true));
        return;
      }
      // โหลดไม่ได้ (เช่น ไม่มีเน็ต) แต่มีของเก่าโชว์อยู่ ไม่ต้องเด้ง error
      if (!showingCache) emit(ProfileFailure(error.message));
    } on Exception catch (error) {
      if (!showingCache) emit(ProfileFailure(error.toString()));
    }
  }
}
