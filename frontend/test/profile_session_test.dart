import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingProfileRepository implements ProfileRepository {
  _FailingProfileRepository(this.error, {this.cached});

  final ProfileRepositoryException error;
  final UserProfile? cached;

  @override
  Future<UserProfile?> cachedProfile() async => cached;

  @override
  Future<UserProfile> fetchProfile(String accessToken) async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<ProfileState>> _load(ProfileRepository repository) async {
  final bloc = ProfileBloc(repository);
  final states = <ProfileState>[];
  final subscription = bloc.stream.listen(states.add);
  bloc.add(const ProfileRequested());
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await bloc.close();
  await subscription.cancel();
  return states;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      TokenStorage.accessTokenKey: 'expired-token',
      TokenStorage.userIdKey: 'u1',
    });
  });

  test(
    'an expired session signs out locally so the user can sign in again',
    () async {
      final states = await _load(
        _FailingProfileRepository(
          const ProfileRepositoryException('expired', sessionExpired: true),
          cached: UserProfile.guest(),
        ),
      );

      final last = states.last;
      expect(last, isA<ProfileGuest>());
      expect((last as ProfileGuest).sessionExpired, isTrue);
      expect(await TokenStorage().readAccessToken(), isNull);
      expect(TokenStorage.currentUserId.value, isNull);
    },
  );

  test('other errors keep the session', () async {
    final states = await _load(
      _FailingProfileRepository(const ProfileRepositoryException('HTTP 500')),
    );

    expect(states.last, isA<ProfileFailure>());
    expect(await TokenStorage().readAccessToken(), 'expired-token');
  });
}
