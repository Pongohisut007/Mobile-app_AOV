import 'package:flutter_application_1/models/user_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileGuest extends ProfileState {
  const ProfileGuest({this.sessionExpired = false});

  /// true = เคย login แต่ session หมดอายุ (เพิ่งล้าง token ทิ้ง) ให้แจ้งผู้ใช้ด้วย
  final bool sessionExpired;
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final UserProfile profile;
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;
}
