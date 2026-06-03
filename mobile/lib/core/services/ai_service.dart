abstract class AiService {
  /// Gửi prompt phân tích kịch bản tài chính đến AI và nhận về nội dung phân tích (dạng markdown/text)
  Future<String> generateScenarioSimulation(String prompt);
}
