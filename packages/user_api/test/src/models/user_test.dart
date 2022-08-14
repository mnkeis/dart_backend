import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:user_api/src/models/user.dart';

void main() {
  const user = User(
    id: 1,
    username: 'username',
    email: 'user@example.com',
    name: 'given name',
    phone: '111-11-11',
    photoUrl: 'image.jpg',
    roles: [Roles.admin, Roles.user],
    refreshTokens: ['first-refresh-token', 'second-refresh-token'],
  );
  const json = <String, dynamic>{
    'id': 1,
    'username': 'username',
    'email': 'user@example.com',
    'name': 'given name',
    'phone': '111-11-11',
    'photoUrl': 'image.jpg',
    'roles': ['admin', 'user'],
    'refreshTokens': ['first-refresh-token', 'second-refresh-token'],
  };
  group('User', () {
    test('can be instatiated', () {
      expect(
        const User(id: 1, username: 'username', email: 'user@example.com'),
        isNotNull,
      );
    });
    group('fromJson', () {
      test('builds an instance', () {
        expect(User.fromJson(json), user);
      });
    });
    group('toJson', () {
      test('converts instance to Map<String, dynamic>', () {
        expect(user.toJson(), json);
      });
    });
  });
}
