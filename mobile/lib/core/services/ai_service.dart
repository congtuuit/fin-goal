abstract class AiService {
  /// Gửi prompt phân tích kịch bản tài chính đến AI và nhận về nội dung phân tích (dạng markdown/text).
  /// [LEGACY] Dùng cho màn hình Scenarios hiện có.
  Future<String> generateScenarioSimulation(String prompt);

  /// Gửi prompt bất kỳ đến AI và nhận về văn bản.
  /// Dùng cho Coach feature — prompt được build bởi [AiPromptBuilder].
  Future<String> chat(String prompt);
}

