// ignore_for_file: prefer_const_constructors
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_api/user_api.dart';
import 'package:user_repository/user_repository.dart';

class _MockUserApi extends Mock implements UserApi {}

void main() {
  final userApi = _MockUserApi();
  group('UserRepository', () {
    test('can be instantiated', () {
      expect(UserRepository(userApi), isNotNull);
    });
  });
}
