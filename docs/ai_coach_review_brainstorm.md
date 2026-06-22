# 🔍 Review & Brainstorm: AI Financial Coach (Fin-Goal)

> **Trạng thái codebase hiện tại:** Tốt hơn kế hoạch ban đầu nhiều! Code đã có nền tảng, KHÔNG phải bắt đầu từ số 0.

---

## ✅ Những Gì Đã Tốt (Cần Giữ Nguyên)

### 1. Architecture sẵn sàng ✨
- **`AiService` interface** đã tồn tại tại `core/services/ai_service.dart` — thiết kế đúng pattern để swap implementation.
- **`DirectClientAiService`** đã implement cả Gemini lẫn OpenAI, có timeout 15s, error handling bằng tiếng Việt.
- **`aiServiceProvider`** (Riverpod) đã bind sẵn — chỉ cần inject và gọi.
- **`ScenarioEngine`** pure Dart, không dependency — module này là vàng! Tính toán đa kịch bản (best/expected/worst case) cực kỳ phù hợp để làm dữ liệu đầu vào cho AI phân tích.

### 2. Settings/Profile UI hoàn chỉnh
Màn hình `settings_page.dart` đã có đầy đủ: chọn provider, nhập model, nhập API Key, có nút Test + Lưu.

### 3. Domain model `Goal` phong phú
Entity `Goal` có đủ: `targetAmount`, `currentSavings`, `monthlySaving`, `type` (mua nhà, xe, du lịch...) — AI sẽ có context rất tốt để phân tích.

---

## ⚠️ Lỗ Hổng Kế Hoạch Cũ (Cần Sửa)

| Vấn đề | Mức độ | Phân tích |
|--------|--------|-----------|
| **Phase 01 đề xuất tạo lại interface đã có** | 🔴 Cao | `AiService` đã tồn tại! Tạo thêm `ai_assistant_service.dart` sẽ gây trùng lặp, làm rối architecture. |
| **Chưa có caching layer** | 🔴 Cao | Không caching = gọi AI mỗi khi render, tốn tiền API, trải nghiệm chậm. |
| **`AiService` chỉ có 1 method duy nhất** | 🟡 Trung bình | `generateScenarioSimulation(String prompt)` quá generic. Cần các method có type-safe hơn cho từng use case (phân tích mục tiêu, tạo kịch bản, v.v.). |
| **Không có Prompt Engineering** | 🔴 Cao | Gọi AI với prompt thô không có hệ thống prompt tốt = câu trả lời chất lượng thấp, không nhất quán. |
| **`coach/` feature folder rỗng hoàn toàn** | 🟡 Trung bình | Có folder `features/coach` nhưng không có file nào — đây là nơi đúng để đặt logic AI Coach. |
| **Chưa có fallback khi không có API Key** | 🟡 Trung bình | App cần hoạt động tốt ngay cả khi user chưa cấu hình AI (show banner gợi ý thay vì crash). |

---

## 💡 Brainstorm: 10 Ý Tưởng Tối Ưu Giá Trị Cao

### 🥇 TIER 1: Triển khai ngay (Cao - Dễ)

#### 1. 🧠 Prompt Library (System Prompt + Context Injection)
**Vấn đề hiện tại:** Gọi AI bằng prompt thô = kết quả không nhất quán, đôi khi AI trả về tiếng Anh hoặc nói chuyện như chatbot thông thường.

**Giải pháp:** Tạo một `AiPromptBuilder` class chịu trách nhiệm duy nhất là xây dựng prompt.
```dart
// Ví dụ prompt hoàn chỉnh:
// SYSTEM: "Bạn là chuyên gia tài chính cá nhân của Fin-Goal. 
//          Chỉ dùng tiếng Việt. Tông giọng: ân cần, thực tế, không phán xét.
//          QUAN TRỌNG: Không đưa lời khuyên đầu tư, chỉ phân tích mô phỏng."
// USER: "Mục tiêu: Mua nhà 2 tỷ. Đã tích lũy: 200tr. Tiết kiệm/tháng: 10tr.
//        Kịch bản tốt nhất: 18 tháng. Kỳ vọng: 22 tháng. Xấu nhất: 30 tháng."
// TASK: "Nhận xét ngắn gọn tiến độ và đưa 1 gợi ý thực tế."
```
**Impact:** Chất lượng câu trả lời tăng vọt, nhất quán, đúng tone của app.

---

#### 2. 💾 Smart Caching (Session-based)
**Vấn đề:** Mỗi lần user scroll qua dashboard = gọi API = tốn tiền + chậm.

**Giải pháp:** Cache theo `goalId + ngày` sử dụng `SharedPreferences`.
- Cache key: `ai_advice_${goalId}_${yyyyMMdd}`
- Expire: Tự động expire sau 24 giờ hoặc khi user cập nhật `currentSavings`.
- Hiển thị timestamp: "Phân tích lúc 9:30 AM · Làm mới"

**Impact:** Giảm 90%+ lượng API call, trải nghiệm nhanh gấp 10x khi mở lại app.

---

#### 3. 🎭 Coach Persona + Tone Adjustment
**Vấn đề:** AI generic không có personality.

**Giải pháp:** Cho user chọn "phong cách huấn luyện viên":
- 💪 **Nghiêm khắc** ("Anh cần tiết kiệm thêm 2 triệu/tháng ngay!")
- 😊 **Ân cần** ("Bạn đang đi đúng hướng rồi, tiếp tục nhé!")
- 📊 **Phân tích** ("Dựa trên xu hướng 3 tháng qua, ...")

**Impact:** Cá nhân hóa trải nghiệm — tăng engagement đáng kể.

---

### 🥈 TIER 2: Triển khai sau (Cao - Phức tạp hơn)

#### 4. 🔗 ScenarioEngine → AI Pipeline
**Đây là ý tưởng mạnh nhất về mặt kỹ thuật.**

Hiện tại `ScenarioEngine` tính toán số học. AI có thể diễn giải kết quả đó thành ngôn ngữ tự nhiên.

**Pipeline:**
```
Goal data → ScenarioEngine.calculate() → ScenarioResult → AiPromptBuilder → AI → "Lời khuyên"
```

AI không cần tính lại số — ScenarioEngine đã làm rồi, AI chỉ cần diễn giải. Đây là sự kết hợp hoàn hảo: tính toán chính xác 100% (từ Dart engine) + ngôn ngữ tự nhiên linh hoạt (từ AI).

**Impact:** AI không bịa số, app đáng tin cậy hơn, giảm rủi ro pháp lý.

---

#### 5. 📅 Proactive AI Coaching (Push Notification)
**Kết hợp với `NotificationService` đã có:**
- Ngày 1 hàng tháng: "Coach nhắc nhở: Bạn cần đặt 10tr vào mục tiêu mua nhà tháng này!"
- Khi tiến độ chậm: "Coach phát hiện: Mục tiêu du lịch của bạn có thể chậm 2 tháng."
- Khi đạt milestone: "Chúc mừng! Bạn đã đạt 50% mục tiêu mua xe! 🎉"

**Impact:** Giữ chân người dùng (retention), tạo habit loop.

---

#### 6. 💬 AI Chat Interface trong Goal Detail
Thay vì chỉ hiển thị 1 card nhận xét, cho phép user "hỏi" Coach:
- "Nếu mình tăng tiết kiệm thêm 2 triệu thì sao?"
- "Với thu nhập hiện tại, mình có thể mua xe 500 triệu trong bao lâu?"

**Quan trọng:** AI vẫn gọi `ScenarioEngine` để lấy số liệu trước khi trả lời.

---

#### 7. 📊 AI-Generated "What-If" Cards
`ScenarioEngine` đã có `whatIfPurchaseImpact()`. Kết hợp với AI để tạo "Insight Cards":

> "💡 Nếu bạn mua iPhone 20tr, mục tiêu mua nhà sẽ lùi lại 2 tháng. Worth it không?"

---

### 🥉 TIER 3: Tương lai (Premium features)

#### 8. 🏆 "Financial Health Score" AI
Tổng hợp tất cả mục tiêu của user → AI tính một "điểm sức khỏe tài chính" 0-100 kèm giải thích chi tiết.

#### 9. 📝 AI Goal Creation Wizard
Thay vì user điền form tạo mục tiêu, chat với AI: "Mình muốn mua nhà ở Hà Nội khoảng 3 tỷ trong 7 năm" → AI tự điền form.

#### 10. 🔮 Annual Financial Review
Cuối năm, AI tổng kết năm tài chính của user, highlight thành tựu và đặt mục tiêu năm mới.

---

## 📐 Kiến Trúc Đề Xuất (Cập Nhật)

```
core/services/
├── ai_service.dart          ← Mở rộng interface (thêm method)  [MODIFY]
├── direct_client_ai_service.dart  ← Giữ nguyên, thêm method     [MODIFY]
├── ai_provider.dart         ← Giữ nguyên                        [KEEP]
└── ai_prompt_builder.dart   ← Tạo mới: Quản lý toàn bộ prompt  [NEW ⭐]

features/coach/
├── domain/
│   ├── entities/coach_advice.dart   ← DTO kết quả AI            [NEW]
│   └── usecases/get_goal_advice.dart ← Use case kết hợp Engine+AI [NEW]
├── data/
│   └── repositories/coach_repository_impl.dart  ← Cache logic    [NEW]
└── presentation/
    ├── providers/coach_provider.dart    ← Riverpod state          [NEW]
    └── widgets/ai_coach_card.dart       ← UI widget               [NEW ⭐]
```

> **Lý do:** Dùng lại `features/coach/` folder đã có thay vì tạo `features/ai_assistant/` mới → tránh fragmentation.

---

## 🚀 Đề Xuất Thứ Tự Triển Khai

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| **1** | Tạo `AiPromptBuilder` với System Prompt chuẩn | S | 🔥🔥🔥 |
| **2** | Mở rộng `AiService` interface thêm `getGoalAdvice()` | S | 🔥🔥🔥 |
| **3** | Implement `CoachRepository` với caching logic | M | 🔥🔥🔥 |
| **4** | Tạo `aiCoachProvider` (Riverpod AsyncNotifier) | S | 🔥🔥 |
| **5** | Tạo widget `AiCoachCard` với shimmer + error fallback UI | M | 🔥🔥🔥 |
| **6** | Kết hợp `ScenarioEngine` → `AiPromptBuilder` pipeline | M | 🔥🔥🔥 |
| **7** | Proactive Notification coaching | L | 🔥🔥 |
| **8** | AI Chat Interface | L | 🔥🔥🔥 |

---

## ⚡ Kết Luận

**Kế hoạch cũ:** Bắt đầu lại từ architecture → mất thời gian vì đã có nền tảng tốt rồi.

**Đề xuất mới:** Tận dụng `AiService`/`DirectClientAiService`/`ScenarioEngine` đã có → tập trung vào:
1. **Prompt Engineering** (tác động lớn nhất, effort thấp nhất)
2. **Caching** (UX tốt hơn, tiết kiệm chi phí)
3. **`features/coach/` feature** (UI + business logic Coach)
4. **Pipeline tích hợp ScenarioEngine → AI** (điểm khác biệt cạnh tranh)

