import 'package:equatable/equatable.dart';

/// Domain entity for the authenticated user.
/// Isolated from Supabase's User model.
class AppUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get hasProfile => displayName != null;

  @override
  List<Object?> get props => [id, email];
}
