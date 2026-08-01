import 'package:flutter_application_1/bloc/user/user_even.dart';
import 'package:flutter_application_1/bloc/user/user_state.dart';
import 'package:flutter_application_1/repositories/product_users.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class Userbloc extends Bloc<UserEven, UserState> {
  final UserRepository repository;

  Userbloc(this.repository) : super(UserInit()) {
    on<FetchUserEvent>(_onFetchUserEvent);
  }

  Future<void> _onFetchUserEvent(
    FetchUserEvent event, 
    Emitter<UserState> emit) async {
    emit(Userloading());
    try {
      final user = await repository.fetchUserEvent();
      emit(Userloaded(user: user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}
