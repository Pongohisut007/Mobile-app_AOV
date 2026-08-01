import 'package:flutter_application_1/models/user.dart';

abstract class UserState {
  UserState();
}

class UserInit extends UserState {
  UserInit();
}

class Userloading extends UserState {
  Userloading();
}

class Userloaded extends UserState {
 final List<User> user;
  Userloaded({required this.user});
}

class UserError extends UserState {
  final String message ;
  UserError({required this.message});
}
