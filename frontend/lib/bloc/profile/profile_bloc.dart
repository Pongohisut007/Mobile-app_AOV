import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileRequested>(_loadProfile);
    on<ProfileRefreshRequested>(_loadProfile);
  }

  final ProfileRepository _repository;

  Future<void> _loadProfile(
    ProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (event is ProfileRequested || state is! ProfileLoaded) {
      emit(const ProfileLoading());
    }
    try {
      final profile = await _repository.fetchProfileById();
      emit(ProfileLoaded(profile));
    } on Exception catch (error) {
      emit(ProfileFailure(error.toString()));
    }
  }
}
