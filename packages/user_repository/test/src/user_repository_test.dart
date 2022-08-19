// ignore_for_file: prefer_const_constructors
import 'package:async/async.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const accessTokenSecret = 'my-access-token-secret';
  const refreshTokenSecret = 'my-refresh-token-secret';
  const username = '__test_username__';
  const password = '__test_password__';
  const email = 'user@example.com';
  final userApi = _MockUserApi();
  final userRepository = UserRepository(
    userApi,
    accessTokenSecret: accessTokenSecret,
    refreshTokenSecret: refreshTokenSecret,
  );
  final user = User(
    id: 1,
    username: username,
    email: email,
  );

  group('UserRepository', () {
    test('can be instantiated', () {
      expect(userRepository, isNotNull);
    });
    group('method createAccessTokenFromUsernameAndPassword', () {
      test('returns valid access and refresh tokens', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final accessToken = jwt.sign(
          SecretKey(accessTokenSecret),
          expiresIn: Duration(hours: 4),
        );
        final refreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration(days: 7),
        );
        final tokens = Tokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => user);
        final updatedUser =
            user.copyWith(refreshTokens: [...user.refreshTokens, refreshToken]);
        when(
          () => userApi.updateUser(updatedUser),
        ).thenAnswer((_) async {});
        final result =
            await userRepository.createAccessTokenFromUsernameAndPassword(
          username: username,
          password: password,
        );
        verify(() => userApi.updateUser(updatedUser)).called(1);
        await expectLater(
          result,
          Result.value(tokens),
        );
      });

      test('returns error when invalid username or passord', () async {
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => null);
        final result =
            await userRepository.createAccessTokenFromUsernameAndPassword(
          username: username,
          password: password,
        );
        final error = result.asError?.error as AuthenticationException?;
        await expectLater(
          error?.failure,
          AuthenticationFailure.invalidUsernameOrPassword,
        );
      });
    });

    group('method createAccessTokenFromRefreshToken', () {
      test('returns valid access and refresh tokens', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final accessToken = jwt.sign(
          SecretKey(accessTokenSecret),
          expiresIn: Duration(hours: 4),
        );
        final refreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration(days: 7),
        );
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration(days: 1),
        );
        final tokens =
            Tokens(accessToken: accessToken, refreshToken: refreshToken);
        when(
          () => userApi.getUserWithRefreshToken(oldRefreshToken),
        ).thenAnswer((_) async => user);
        final updatedUser =
            user.copyWith(refreshTokens: [...user.refreshTokens, refreshToken]);
        when(
          () => userApi.updateUser(updatedUser),
        ).thenAnswer((_) async {});
        final result = await userRepository
            .createAccessTokenFromRefreshToken(oldRefreshToken);
        verify(() => userApi.updateUser(updatedUser)).called(1);
        await expectLater(
          result,
          Result.value(tokens),
        );
      });

      test('returns error if token is expired', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration.zero,
        );
        final result = await userRepository
            .createAccessTokenFromRefreshToken(oldRefreshToken);
        final error = result.asError?.error as TokenException?;
        await expectLater(
          error?.failure,
          TokenFailure.tokenExpired,
        );
      });

      test('returns error if token is invalid', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey('invalid-secret'),
          expiresIn: Duration(days: 1),
        );
        final result = await userRepository
            .createAccessTokenFromRefreshToken(oldRefreshToken);
        final error = result.asError?.error as TokenException?;
        await expectLater(
          error?.failure,
          TokenFailure.tokenInvalid,
        );
      });

      test('returns error if token is reused', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration(days: 1),
        );
        when(
          () => userApi.getUserWithRefreshToken(oldRefreshToken),
        ).thenAnswer((_) async => null);
        when(
          () => userApi.getUserById(1),
        ).thenAnswer((_) async => user);
        final updatedUser = user.copyWith(refreshTokens: []);
        when(
          () => userApi.updateUser(updatedUser),
        ).thenAnswer((_) async {});
        final result = await userRepository
            .createAccessTokenFromRefreshToken(oldRefreshToken);
        final error = result.asError?.error as TokenException?;
        verify(() => userApi.getUserById(1)).called(1);
        verify(() => userApi.updateUser(updatedUser)).called(1);
        await expectLater(
          error?.failure,
          TokenFailure.refreshTokenReused,
        );
      });
    });

    group('method addUser', () {
      test('executes successfully', () async {
        when(() => userApi.createUser(user: user, password: password))
            .thenAnswer((_) async => true);
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((invocation) async => user);
        final result =
            await userRepository.addUser(user: user, password: password);
        expect(result.asValue?.value, equals(user));
      });
    });

    group('method logoutFromAllDevices', () {
      test('executes succesfully', () async {
        when(() => userApi.getUserById(1)).thenAnswer((_) async => user);
        when(() => userApi.updateUser(user.copyWith(refreshTokens: [])))
            .thenAnswer((_) async {});
        await userRepository.revokeAllRefreshTokens(1);
        verify(() => userApi.updateUser(user)).called(1);
      });
    });

    group('method updatePassword', () {
      test('executes succesfully', () async {
        const newPassword = 'new-password';
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => user);
        await userRepository.updatePassword(
          username: username,
          password: password,
          newPassword: newPassword,
        );
        verify(
          () => userApi.updateUserPassword(user: user, password: newPassword),
        ).called(1);
      });

      test('returns error if no user found', () async {
        const newPassword = 'new-password';
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => null);
        final result = await userRepository.updatePassword(
          username: username,
          password: password,
          newPassword: newPassword,
        );
        await expectLater(
          result,
          Result<void>.error(
            const AuthenticationException(
              AuthenticationFailure.invalidUsernameOrPassword,
            ),
          ),
        );
      });
    });
  });
}
