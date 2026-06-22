import 'package:equatable/equatable.dart';

/// Domain entity representing AI-generated coaching advice for a goal.
class CoachAdvice extends Equatable {
  /// The goal ID this advice is for.
  final String goalId;

  /// The AI-generated advice text (in Vietnamese).
  final String adviceText;

  /// When this advice was generated. Used for cache expiry.
  final DateTime generatedAt;

  /// Whether this is a cached response (shown to user as context).
  final bool isFromCache;

  const CoachAdvice({
    required this.goalId,
    required this.adviceText,
    required this.generatedAt,
    this.isFromCache = false,
  });

  /// Returns true if this advice is considered stale (older than 24 hours).
  bool get isExpired {
    return DateTime.now().difference(generatedAt).inHours >= 24;
  }

  /// Formatted time string for display (e.g., "9:30 SA").
  String get formattedTime {
    final h = generatedAt.hour;
    final m = generatedAt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'SA' : 'CH';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }

  CoachAdvice copyWith({
    String? goalId,
    String? adviceText,
    DateTime? generatedAt,
    bool? isFromCache,
  }) {
    return CoachAdvice(
      goalId: goalId ?? this.goalId,
      adviceText: adviceText ?? this.adviceText,
      generatedAt: generatedAt ?? this.generatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [goalId, adviceText, generatedAt, isFromCache];
}
