import 'dart:convert';
import 'package:fin_goal/core/services/ai_service.dart';
import 'package:fin_goal/features/cashflow/domain/entities/cashflow_state.dart';
import 'package:fin_goal/features/cashflow/domain/entities/game_scenario.dart';

class CashflowAiEngine {
  final AiService _aiService;

  const CashflowAiEngine(this._aiService);

  Future<GameScenario> generateScenario(CashflowState state) async {
    final prompt = '''
Bạn là một "Game Master" của một trò chơi mô phỏng dòng tiền (giống Cashflow của Robert Kiyosaki).
Người chơi đang ở tháng thứ ${state.currentMonth}.
Tài chính hiện tại của họ:
- Tiền mặt: ${state.cashOnHand} VND
- Tổng thu nhập (Lương + Thụ động): ${state.totalIncome} VND
- Tổng chi phí (Sinh hoạt + Trả nợ): ${state.totalExpenses} VND
- Dòng tiền hàng tháng (Cashflow): ${state.monthlyCashflow} VND
- Tiến độ tự do tài chính: ${(state.financialFreedomProgress * 100).toStringAsFixed(1)}%

Nhiệm vụ của bạn: Tạo ra MỘT tình huống tài chính ngẫu nhiên trong tháng này.
Tình huống có thể là:
- Cơ hội đầu tư (Chứng khoán, Bất động sản, Góp vốn kinh doanh)
- Biến cố bất ngờ (Hỏng xe, Ốm đau, Đám cưới)
- Mua sắm tiêu dùng (Mua điện thoại mới, Đi du lịch)

Yêu cầu:
1. Tạo ra 3 lựa chọn cho người chơi (Ví dụ: A: Bỏ qua, B: Đầu tư bằng tiền mặt, C: Vay nợ để đầu tư).
2. Tác động của mỗi lựa chọn phải hợp lý. (Mua tiêu sản thì mất tiền mặt, tăng chi phí. Mua tài sản thì mất tiền mặt/tăng nợ, nhưng tăng thu nhập thụ động).
3. TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON MÀ KHÔNG CÓ BẤT KỲ VĂN BẢN NÀO KHÁC BÊN NGOÀI (Không markdown block).

Định dạng JSON yêu cầu:
{
  "id": "scenario_1",
  "title": "Tên kịch bản ngắn gọn",
  "description": "Mô tả chi tiết tình huống...",
  "options": [
    {
      "id": "opt_1",
      "title": "Tên lựa chọn 1",
      "description": "Mô tả hành động",
      "aiFeedback": "Đánh giá của bạn về lựa chọn này theo triết lý Cha Giàu Cha Nghèo.",
      "impact": {
        "cashChange": -5000000,
        "activeIncomeChange": 0,
        "baseExpensesChange": 500000,
        "addedAssets": [],
        "addedLiabilities": [
          {"id": "liab_1", "name": "Trả góp điện thoại", "type": "personalLoan", "totalOwed": 15000000, "monthlyPayment": 500000}
        ]
      }
    }
    // Tương tự cho option 2 và 3
  ]
}

Lưu ý: "addedAssets" chứa các object dạng {"id": "...", "name": "...", "type": "stock/realEstate/business/other", "value": 10000000, "passiveIncome": 500000}.
"addedLiabilities" chứa các object dạng {"id": "...", "name": "...", "type": "mortgage/carLoan/creditCard/personalLoan", "totalOwed": 10000000, "monthlyPayment": 1000000}.
Giá trị tiền tệ phải bằng VND (số nguyên lớn).
Hãy đảm bảo JSON hợp lệ!
''';

    final response = await _aiService.generateScenarioSimulation(prompt);
    
    // Xử lý chuỗi JSON phòng trường hợp AI trả về markdown block (```json ... ```)
    String cleanJson = response.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    }
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    
    final map = jsonDecode(cleanJson.trim()) as Map<String, dynamic>;
    return GameScenario.fromJson(map);
  }
}
