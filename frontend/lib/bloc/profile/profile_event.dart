import 'package:flutter_application_1/models/user_profile.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

final class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

/// แก้โปรไฟล์สำเร็จ backend ส่งโปรไฟล์ล่าสุดกลับมาแล้ว โชว์เลยไม่ต้องโหลดใหม่
final class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated(this.profile);

  final UserProfile profile;
}
