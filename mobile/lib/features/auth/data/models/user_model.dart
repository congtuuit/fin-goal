import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:fin_goal/features/auth/domain/entities/app_user.dart';

class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromSupabase(sb.User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['full_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );
}
