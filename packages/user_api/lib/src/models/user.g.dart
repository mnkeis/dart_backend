part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      roles: List<Roles>.from(
        (json['roles'] as Iterable? ?? [])
            .map((e) => Roles.fromString(e as String)),
      ),
      refreshTokens: List<String>.from(
        (json['refreshTokens'] as Iterable? ?? []).map((e) => e as String),
      ),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'name': instance.name,
      'phone': instance.phone,
      'photoUrl': instance.photoUrl,
      'roles': instance.roles.map((e) => e.name).toList(),
      'refreshTokens': instance.refreshTokens,
    };
