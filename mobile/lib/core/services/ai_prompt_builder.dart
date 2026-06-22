import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_result.dart';

/// Phong cách tư vấn của AI Coach.
enum CoachTone {
  /// Ân cần, động viên, phù hợp cho người mới bắt đầu.
  encouraging,

  /// Thực tế, phân tích số liệu, phù hợp cho người thích data.
  analytical,

  /// Nghiêm khắc, thúc đẩy hành động, phù hợp cho người cần kỷ luật cao.
  strict,
}

/// Builds structured prompts for the AI Financial Coach.
///
/// Responsibilities:
/// 1. Inject a system role to keep AI on-topic and in Vietnamese.
/// 2. Format Goal + ScenarioResult data into a clear context block.
/// 3. Give the AI a specific, bounded task (no hallucinated numbers).
///
/// PHILOSOPHY: ScenarioEngine owns the math. AiPromptBuilder owns the language.
/// AI must NEVER invent numbers — only interpret data we provide.
class AiPromptBuilder {
  const AiPromptBuilder();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Builds a full prompt for the Goal Advice use case.
  ///
  /// Combines system instructions + financial context + a bounded task.
  String buildGoalAdvicePrompt({
    required Goal goal,
    required ScenarioResult result,
    CoachTone tone = CoachTone.encouraging,
  }) {
    final system = _buildSystemPrompt(tone);
    final context = _buildGoalContext(goal, result);
    final task = _buildGoalAdviceTask();
    return '$system\n\n$context\n\n$task';
  }

  /// Builds a prompt to generate a 3-line financial health summary
  /// across multiple goals.
  String buildHealthSummaryPrompt({
    required List<Goal> goals,
    CoachTone tone = CoachTone.encouraging,
  }) {
    final system = _buildSystemPrompt(tone);
    final context = _buildMultiGoalContext(goals);
    const task = '''---
NHIỆM VỤ:
Viết một đoạn nhận xét ngắn (tối đa 3 câu) về sức khỏe tài chính tổng thể của người dùng dựa trên các mục tiêu trên.
Kết thúc bằng 1 câu hành động cụ thể nhất mà họ nên làm ngay hôm nay.
Chỉ dùng tiếng Việt. Không hỏi lại. Không đưa khuyến nghị đầu tư.''';
    return '$system\n\n$context\n\n$task';
  }

  /// Builds a "What-If" prompt: what happens if user makes a one-time purchase.
  String buildWhatIfPrompt({
    required Goal goal,
    required int purchaseCostVnd,
    required int delayMonths,
    CoachTone tone = CoachTone.analytical,
  }) {
    final system = _buildSystemPrompt(tone);
    final goalName = goal.name;
    final cost = _formatVnd(purchaseCostVnd);
    final context = '''---
THÔNG TIN:
- Mục tiêu: $goalName
- Chi phí dự kiến mua: $cost
- Nếu mua, mục tiêu sẽ bị trễ thêm: $delayMonths tháng''';
    const task = '''---
NHIỆM VỤ:
Giải thích tác động của khoản chi tiêu này lên mục tiêu bằng ngôn ngữ thực tế, thân thiện (tối đa 2 câu).
Đừng phán xét quyết định của người dùng. Kết thúc bằng câu hỏi mở nhẹ nhàng.
Chỉ dùng tiếng Việt.''';
    return '$system\n\n$context\n\n$task';
  }

  // ---------------------------------------------------------------------------
  // Private builders
  // ---------------------------------------------------------------------------

  String _buildSystemPrompt(CoachTone tone) {
    final toneInstruction = switch (tone) {
      CoachTone.encouraging =>
        'Tông giọng: Ấm áp, động viên, không phán xét. Như một người bạn hiểu biết về tài chính.',
      CoachTone.analytical =>
        'Tông giọng: Khách quan, tập trung số liệu. Phân tích rõ ràng, dễ hiểu.',
      CoachTone.strict =>
        'Tông giọng: Thẳng thắn, thúc đẩy hành động. Không vòng vo, tập trung vào việc cần làm ngay.',
    };

    return '''VAI TRÒ:
Bạn là AI Financial Coach của ứng dụng Fin-Goal — một trợ lý tài chính cá nhân thông minh.

QUY TẮC BẮT BUỘC:
1. CHỈ dùng tiếng Việt trong mọi câu trả lời.
2. KHÔNG đưa ra khuyến nghị mua/bán cổ phiếu, crypto, hay bất kỳ tài sản đầu tư cụ thể nào.
3. KHÔNG tự bịa đặt số liệu — chỉ diễn giải dữ liệu được cung cấp.
4. Giữ câu trả lời ngắn gọn (tối đa 4 câu) trừ khi được yêu cầu dài hơn.
5. Kết thúc LUÔN LUÔN bằng một hành động cụ thể người dùng có thể làm ngay.
$toneInstruction''';
  }

  String _buildGoalContext(Goal goal, ScenarioResult result) {
    final progress = goal.targetAmount > 0
        ? (goal.currentSavings / goal.targetAmount * 100).clamp(0, 100)
        : 0.0;
    final goalTypeName = _goalTypeToVietnamese(goal.type);

    return '''---
DỮ LIỆU MỤC TIÊU (do ScenarioEngine tính toán — KHÔNG tự sửa số):
- Tên mục tiêu: ${goal.name} (Loại: $goalTypeName)
- Số tiền cần đạt: ${_formatVnd(goal.targetAmount)}
- Đã tích lũy: ${_formatVnd(goal.currentSavings)} (${progress.toStringAsFixed(1)}% hoàn thành)
- Còn cần: ${_formatVnd(result.remainingAmount)}
- Tiết kiệm hàng tháng: ${_formatVnd(goal.monthlySaving)}
- Kịch bản tốt nhất: ${result.bestCaseMonths} tháng nữa
- Kịch bản kỳ vọng: ${result.expectedMonths} tháng nữa
- Kịch bản xấu nhất: ${result.worstCaseMonths} tháng nữa
- Độ tin cậy của kế hoạch: ${result.planReliability.toStringAsFixed(0)}%''';
  }

  String _buildGoalAdviceTask() {
    return '''---
NHIỆM VỤ:
Nhận xét ngắn gọn về tiến độ của người dùng (1-2 câu) dựa trên dữ liệu trên.
Sau đó đưa ra 1 gợi ý thực tế và cụ thể nhất để giúp họ đạt mục tiêu nhanh hơn hoặc đúng hạn hơn.
Chỉ dùng tiếng Việt. Không hỏi lại. Không đưa khuyến nghị đầu tư.''';
  }

  String _buildMultiGoalContext(List<Goal> goals) {
    if (goals.isEmpty) {
      return '---\nNgười dùng chưa có mục tiêu tài chính nào.';
    }
    final buffer = StringBuffer('---\nCÁC MỤC TIÊU TÀI CHÍNH:\n');
    for (final g in goals) {
      final progress = g.targetAmount > 0
          ? (g.currentSavings / g.targetAmount * 100).clamp(0, 100)
          : 0.0;
      buffer.writeln(
          '- ${g.name}: ${_formatVnd(g.currentSavings)}/${_formatVnd(g.targetAmount)} (${progress.toStringAsFixed(0)}%)');
    }
    return buffer.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatVnd(int amount) {
    if (amount >= 1000000000) {
      final bil = amount / 1000000000;
      return '${bil.toStringAsFixed(bil % 1 == 0 ? 0 : 1)} tỷ';
    }
    if (amount >= 1000000) {
      final mil = amount / 1000000;
      return '${mil.toStringAsFixed(mil % 1 == 0 ? 0 : 0)} triệu';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$amount VNĐ';
  }

  String _goalTypeToVietnamese(GoalType type) {
    return switch (type) {
      GoalType.emergencyFund => 'Quỹ khẩn cấp',
      GoalType.car => 'Mua xe',
      GoalType.house => 'Mua nhà',
      GoalType.wedding => 'Đám cưới',
      GoalType.travel => 'Du lịch',
      GoalType.retirement => 'Nghỉ hưu',
      GoalType.custom => 'Tùy chỉnh',
    };
  }
}
