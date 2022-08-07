import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/api/tokens/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const username = '__test_username__';
  const password = '__test_password__';
  group('Tokens', () {
    test('create a new token', () {
      final context = _MockRequestContext();
      final request = Request.post(
        Uri.parse('http://localhost/api/tokens'),
        body: '''
        {
          'username': $username,
          'password': $password,
        }''',
      );
      when(() => context.request).thenReturn(request);
      final response = route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
    });
  });
}
