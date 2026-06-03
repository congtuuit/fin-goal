import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';

import '../../../../core/services/ai_provider.dart';
import '../../domain/entities/scenario_query.dart';

part 'ai_explanation_provider.g.dart';

@riverpod
class AiExplanationNotifier extends _$AiExplanationNotifier {
  @override
  FutureOr<String?> build() {
    return null;
  }

  Future<void> generateExplanationForWhatIf(ScenarioQuery query) async {
    state = const AsyncLoading();

    final prompt = '''
Bạn là một chuyên gia tư vấn tài chính cá nhân thân thiện và thông minh.
Hãy phân tích kịch bản tài chính sau cho tôi:
- Tôi muốn mua món đồ: "${query.itemName}" với giá tiền: ${query.itemCost} VND.
- Việc chi tiêu này làm mục tiêu tài chính của tôi bị chậm lại thêm ${query.impactMonths.toInt()} tháng.

Yêu cầu:
1. Hãy đưa ra nhận xét thân thiện, thực tế về quyết định mua sắm này (ảnh hưởng lớn hay nhỏ đối với cuộc sống của tôi).
2. Đưa ra 2 lời khuyên tài chính cụ thể, thực tế để bù đắp khoảng thời gian bị chậm (ví dụ: tăng tiết kiệm, dời ngày mua, tìm nguồn thu nhập thêm).
3. Trả lời bằng tiếng Việt, ngắn gọn, súc tích (khoảng 3-4 câu), giọng văn chia sẻ và động viên.
''';

    try {
      final aiService = ref.read(aiServiceProvider);
      final explanation = await aiService.generateScenarioSimulation(prompt);
      state = AsyncData(explanation);
    } on HttpException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncError('Không thể kết nối đến AI. Vui lòng kiểm tra lại API Key hoặc kết nối mạng của bạn.', StackTrace.current);
    }
  }
}
