import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/google_sign_in_service.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// เขียน token + userId ลงเครื่องให้เรียบร้อยก่อน emit AuthAuthenticated
// หน้า login/register ถึงสั่งให้ตะกร้ากับหัวใจโหลดใหม่ได้ทันทีโดยอ่านเจอของคนใหม่
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._repository, {
    TokenStorage? tokenStorage,
    GoogleIdTokenProvider? google,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       _google = google ?? GoogleSignInService.instance,
       super(const AuthInitial()) {
    on<AuthLoginRequested>(_login);
    on<AuthRegisterRequested>(_register);
    on<AuthGoogleRequested>(_signInWithGoogle);
    on<AuthSessionStarted>(_startSession);
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final GoogleIdTokenProvider _google;

  Future<void> _signInWithGoogle(
    AuthGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final idToken = await _google.signIn();
      // ปิดหน้าเลือกบัญชีเอง = กลับไปสถานะเดิม ไม่ต้องขึ้น error
      if (idToken == null) {
        emit(const AuthInitial());
        return;
      }
      final response = await _repository.loginWithGoogle(idToken: idToken);
      await _tokenStorage.saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _startSession(
    AuthSessionStarted event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenStorage.saveSession(
      accessToken: event.response.accessToken,
      userId: event.response.user.id,
    );
    emit(AuthAuthenticated(event.response));
  }

  Future<void> _login(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _repository.login(
        email: event.email,
        password: event.password,
      );
      await _tokenStorage.saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _register(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      await _tokenStorage.saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }
}
