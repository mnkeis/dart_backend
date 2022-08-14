import 'package:dart_frog/dart_frog.dart';
import 'package:pg_user_api/pg_user_api.dart';
import 'package:postgres/postgres.dart';
import 'package:user_repository/user_repository.dart';

import '../../../models/models.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<UserRepository>((context) {
      final pg = context.read<PostgreSQLConnection>();
      final tokenEnv = context.read<TokenEnv>();
      return UserRepository(
        PgUserApi(pg),
        accessTokenSecret: tokenEnv.accessTokenSecret,
        accessTokenExpire: tokenEnv.accessTokenExpire,
        refreshTokenSecret: tokenEnv.refreshTokenSecret,
        refreshTokenExpire: tokenEnv.refreshTokenExpire,
      );
    }),
  );
}
