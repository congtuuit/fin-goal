import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    // Tương lai: Gọi Supabase Edge Function
    // final result = await Supabase.instance.client.functions.invoke('ai-explanation', body: query.toJson());

    // Hiện tại: Mock delay và logic trả về giả lập (Simulator, không phải dự đoán)
    await Future.delayed(const Duration(seconds: 2));

    final String text;
    if (query.impactMonths == 0) {
      text = 'Món đồ này (${query.itemName}) gần như không ảnh hưởng đến mục tiêu của bạn. Dựa trên số dư và tốc độ tiết kiệm hiện tại, bạn hoàn toàn có thể mua nó mà không làm chậm kế hoạch.';
    } else if (query.impactMonths <= 3) {
      text = 'Nếu bạn quyết định mua ${query.itemName}, kế hoạch của bạn sẽ chậm lại khoảng ${query.impactMonths.toInt()} tháng. Mức ảnh hưởng này khá nhỏ, bạn có thể cân nhắc tăng nhẹ số tiền tiết kiệm hàng tháng để bù đắp.';
    } else {
      text = 'Việc chi trả cho ${query.itemName} sẽ làm mục tiêu chính của bạn chậm lại đáng kể (${query.impactMonths.toInt()} tháng). Theo dữ liệu tiết kiệm, đây là một khoản chi lớn. Bạn nên cân nhắc xem liệu món đồ này có thực sự cấp thiết hay không.';
    }

    state = AsyncData(text);
  }
}
