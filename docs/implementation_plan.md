# 💰 Financial Scenario Simulator — Kế hoạch Triển khai v3.0
> **Đã chốt:** Flutter · Co-founder kỹ thuật · Beta Closed | PM: Nam

---

## ✅ Tất cả quyết định đã được chốt

| Quyết định | Kết quả |
|-----------|---------|
| Positioning | "Financial Scenario Simulator" — không phải AI dự báo |
| Benchmark | Loại bỏ MVP — thêm khi ≥ 5,000 users có ≥ 6 tháng data |
| AI Timeline | V1 = thuần toán → V2 = AI giải thích → V3 = AI thông minh |
| Mobile Stack | **Flutter** (cross-platform iOS + Android) |
| Team | **Founder (Product)** + **Co-founder (Tech)** |
| Launch mode | **Beta Closed** (TestFlight + Google Play Beta) |

---

## 🔧 Tech Stack Hoàn chỉnh

| Layer | Công nghệ | Version | Ghi chú |
|-------|-----------|---------|---------|
| **Mobile** | Flutter | 3.x (stable) | Cross-platform |
| **State** | Riverpod | 2.x | Compile-safe, testable |
| **Navigation** | Go Router | latest | Deep linking support |
| **DI** | get_it + injectable | latest | Code generation |
| **Network** | Dio + Retrofit | latest | Type-safe API calls |
| **Local DB** | Isar | 3.x | Offline-first, fast |
| **Backend** | Supabase | latest | Auth + DB + Realtime + Storage |
| **AI (V2+)** | OpenAI GPT-4o | via Edge Fn | Không expose key ở client |
| **Payments** | RevenueCat | latest | Quản lý subscription cross-platform |
| **Analytics** | PostHog | latest | Self-hosted option |
| **Push** | Firebase Cloud Messaging | latest | Free, reliable |
| **Error** | Sentry | latest | Crash reporting |
| **CI/CD** | GitHub Actions + Fastlane | - | Auto deploy beta |

> [!TIP]
> **RevenueCat** thay Stripe trực tiếp: Quản lý In-App Purchase (App Store + Google Play) dễ hơn nhiều. Stripe chỉ cần nếu có web payment sau này.

---

## 👥 Team Division

| | Founder (Product) | Co-founder (Tech) |
|--|-------------------|-------------------|
| **Phase 0** | DB Schema design, Copy writing | Flutter setup, Supabase config, CI/CD |
| **Phase 1** | UI components, Onboarding flow UX | Calculation Engine, Auth, Router |
| **Phase 2** | Coach content, Analytics events | FCM integration, Isar local DB |
| **Phase 3** | AI prompt engineering, Paywall UX | OpenAI Edge Function, RevenueCat |
| **Ongoing** | A/B test hypotheses, KPI tracking | Performance, Infra, Security |

---

## 🗄️ Database Schema (Supabase PostgreSQL)

### `users` (Supabase Auth — auto-managed)
```sql
-- Supabase Auth handles này tự động
-- Chỉ cần bảng profile riêng
```

### `financial_profiles`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE
age             INT NOT NULL
monthly_income  BIGINT NOT NULL        -- VND, stored as integer
fixed_expenses  BIGINT NOT NULL        -- VND
current_savings BIGINT NOT NULL DEFAULT 0
salary_date     INT NOT NULL           -- 1-31
currency        VARCHAR(3) DEFAULT 'VND'
created_at      TIMESTAMPTZ DEFAULT NOW()
updated_at      TIMESTAMPTZ DEFAULT NOW()
```

### `goals`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE
type            VARCHAR(50) NOT NULL   -- 'emergency_fund', 'car', 'house', 'wedding', 'travel', 'retirement', 'custom'
name            VARCHAR(255) NOT NULL
target_amount   BIGINT NOT NULL        -- VND
emoji           VARCHAR(10)
is_active       BOOLEAN DEFAULT TRUE
is_primary      BOOLEAN DEFAULT FALSE  -- Free tier: chỉ 1 goal active
created_at      TIMESTAMPTZ DEFAULT NOW()
```

### `monthly_records`
```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE
goal_id             UUID REFERENCES goals(id) ON DELETE CASCADE
record_month        DATE NOT NULL              -- first day of month
planned_savings     BIGINT NOT NULL            -- VND
actual_savings      BIGINT                     -- NULL nếu chưa nhập
variance_percent    DECIMAL(5,2)               -- auto-calculated
plan_reliability    DECIMAL(5,2)               -- 0-100%
notes               TEXT
created_at          TIMESTAMPTZ DEFAULT NOW()
UNIQUE(user_id, goal_id, record_month)
```

### `scenario_queries`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE
goal_id         UUID REFERENCES goals(id)
item_name       VARCHAR(255) NOT NULL
item_cost       BIGINT NOT NULL
impact_months   DECIMAL(5,1)                   -- tháng bị chậm
best_case_months    INT
expected_months     INT
worst_case_months   INT
ai_explanation  TEXT                           -- NULL cho V1, có ở V2
created_at      TIMESTAMPTZ DEFAULT NOW()
```

### `user_subscriptions`
```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE
tier                VARCHAR(20) DEFAULT 'free'  -- 'free', 'premium', 'family'
revenuecat_id       VARCHAR(255)
expires_at          TIMESTAMPTZ
created_at          TIMESTAMPTZ DEFAULT NOW()
```

### Row Level Security (RLS)
```sql
-- Mỗi user chỉ thấy data của mình
ALTER TABLE financial_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_records ENABLE ROW LEVEL SECURITY;
-- v.v.
```

---

## 🧮 Calculation Engine Logic

Engine này là pure Dart, không có external deps, có thể unit test 100%:

```dart
// Đầu vào
class ScenarioInput {
  final int currentSavings;      // VND
  final int monthlySaving;       // VND
  final int targetAmount;        // VND
  final double inflationRate;    // default: 0.05 (5%/năm)
  final double varianceBuffer;   // default: 0.15 (±15%)
}

// Đầu ra
class ScenarioResult {
  final int bestCaseMonths;      // Expected × 0.80
  final int expectedMonths;      // (target - savings) / monthly
  final int worstCaseMonths;     // Expected × 1.30
  final double planReliability;  // 40% ban đầu, tăng theo data
}
```

**Plan Reliability Formula:**
```
base = 40.0
+ (monthsWithData * 5.0)          // +5% mỗi tháng có data thực
+ (variance < 0.10 ? 10.0 : 0.0)  // +10% nếu variance < 10%
- (variance > 0.30 ? 5.0 : 0.0)   // -5% nếu variance > 30%
reliability = min(base, 95.0)      // max 95% — never 100%
```

---

## 📋 Sprint Plan Chi tiết

---

### 🔲 PHASE 0 — Foundation (Tuần -2 đến -1)

#### Sprint 0A — Tuần -2: Architecture Setup
**Co-founder:**
- [ ] Flutter project init với Flavor (dev/staging/prod)
- [ ] Setup Riverpod + Go Router + get_it
- [ ] Supabase project tạo + config RLS
- [ ] GitHub Actions: lint → test → build
- [ ] Fastlane setup cho TestFlight + Play Beta
- [ ] Sentry + PostHog integration

**Founder:**
- [ ] Figma design system: colors, typography, components
- [ ] Copy writing cho toàn bộ onboarding flow
- [ ] TestFlight app group setup + Google Play Closed Testing
- [ ] Viết DB migration files

**Deliverable:** Repo chạy được trên cả iOS và Android, deploy lên Beta channel

---

#### Sprint 0B — Tuần -1: Core Engine
**Co-founder:**
- [ ] Implement Calculation Engine (pure Dart) với unit tests đầy đủ
- [ ] Supabase migrations: tất cả tables
- [ ] Auth flow: Email/Google Sign-in
- [ ] Isar schema cho offline cache

**Founder:**
- [ ] Design + prototype Scenario Dashboard screen
- [ ] Viết unit test cases cho Calculation Engine
- [ ] Chuẩn bị beta user list (50–100 người)

**Deliverable:** Calculation Engine pass 100% tests, Auth hoạt động

---

### 🔲 PHASE 1 — MVP V1: Goal Planner (Tuần 1–4)

#### Sprint 1 — Tuần 1-2: Onboarding + Financial Profile
**Co-founder:**
- [ ] Financial Profile repository + usecase
- [ ] Riverpod providers cho profile state
- [ ] Supabase CRUD cho financial_profiles
- [ ] Offline-first với Isar sync

**Founder:**
- [ ] Onboarding wizard UI (5 steps, slide animation)
- [ ] Smart validation logic (income vs expenses check)
- [ ] "Khả năng tiết kiệm ước tính" real-time display
- [ ] PostHog events: `onboarding_started`, `onboarding_completed`

**Deliverable:** User có thể tạo Financial Profile

---

#### Sprint 2 — Tuần 3-4: Goal Selection + Scenario Dashboard
**Co-founder:**
- [ ] Goals repository + usecases
- [ ] ScenarioResult integration với Calculation Engine
- [ ] monthly_records CRUD
- [ ] scenario_queries logging

**Founder:**
- [ ] Goal Selection UI với emotional hooks + animations
- [ ] Scenario Dashboard UI:
  - Confidence Range display (Best/Expected/Worst)
  - Plan Reliability indicator
  - Sensitivity slider (real-time recalculation)
- [ ] Viral Card generator (share image)
- [ ] Disclaimer text component

**Deliverable:** Core 3-screen flow hoàn chỉnh → Deploy Beta đầu tiên

---

### 🔲 PHASE 2 — Weekly Self-Coach (Tuần 5–8)

#### Sprint 3 — Tuần 5-6: Monthly Recalibration
**Co-founder:**
- [ ] Monthly recalibration logic + variance calculation
- [ ] Plan Reliability score update algorithm
- [ ] FCM setup + notification scheduling
- [ ] Background sync khi app mở

**Founder:**
- [ ] Monthly check-in UI flow
- [ ] "Kế hoạch đã cập nhật" confirmation screen
- [ ] Progress timeline visualization
- [ ] PostHog events: `recalibration_completed`, `plan_reliability_viewed`

**Deliverable:** User có thể cập nhật tiết kiệm thực tế hàng tháng

---

#### Sprint 4 — Tuần 7-8: Quick Decision Widget + Coach Insights
**Co-founder:**
- [ ] Coach insights calculation (week-over-week comparison)
- [ ] Push notification scheduling logic
- [ ] Deeplink từ notification vào đúng screen

**Founder:**
- [ ] Quick Decision Widget UI: "Nếu mua X → chậm Y tháng"
- [ ] Weekly Coach card UI (3 loại insights)
- [ ] Notification preference settings
- [ ] Home dashboard redesign với tất cả widget

**Deliverable:** Weekly self-coach flow hoạt động end-to-end

---

### 🔲 PHASE 3 — AI Layer V2 + Premium (Tuần 9–12)

#### Sprint 5 — Tuần 9-10: AI Explanation Engine
**Co-founder:**
- [ ] Supabase Edge Function: `ai-explanation` (OpenAI GPT-4o)
- [ ] Prompt engineering cho financial scenarios
- [ ] Rate limiting + error handling
- [ ] Cache AI responses (tránh duplicate calls)

**Founder:**
- [ ] AI explanation UI component (streaming text effect)
- [ ] "AI đang phân tích..." loading state
- [ ] A/B test: có/không AI explanation → measure engagement

**Supabase Edge Function:**
```typescript
// functions/ai-explanation/index.ts
// Input: scenario_query_id
// Output: plain text explanation
// Gọi OpenAI, không expose API key ra client
```

**Deliverable:** AI giải thích kết quả Scenario Calculator

---

#### Sprint 6 — Tuần 11-12: Premium Paywall + RevenueCat
**Co-founder:**
- [ ] RevenueCat integration (iOS + Android)
- [ ] Subscription tiers config: Free / Premium / Family
- [ ] Entitlements check trong app
- [ ] Webhook Supabase cập nhật `user_subscriptions`

**Founder:**
- [ ] Paywall UI: Premium value proposition
- [ ] Feature gating: Free = 3 scenarios/tháng, Premium = unlimited
- [ ] "Upgrade to Premium" contextual prompts
- [ ] Annual plan upsell (599K/năm)

**Deliverable:** Monetization hoạt động end-to-end

---

### ⚖️ PMF Checkpoint — Tuần 13

**Việc cần làm:**
- [ ] Xuất PostHog dashboard: D7/D30 Retention, AI usage, conversion
- [ ] Survey beta users: Sean Ellis Test (Google Form)
- [ ] Review qualitative feedback từ TestFlight/Play Beta
- [ ] Go/No-Go decision meeting

| Điều kiện GO | Metric |
|-------------|--------|
| D30 Retention | ≥ 30% |
| Monthly recalibration rate | ≥ 40% |
| Premium conversion | ≥ 3% |
| Sean Ellis "rất thất vọng" | ≥ 40% |

---

### 🔲 PHASE 4+ — Scale (Tuần 14+, điều kiện: PMF đạt)

**Phase 4 (T4):** Couple Finance — Shared Goals, Joint Scenario Calculator  
**Phase 5 (T5):** Family Finance, Referral Program  
**Phase 6 (T6):** Platform Stability, AI V3 prep (khi ≥ 5,000 users)

---

## 📊 KPI Dashboard

| Tháng | North Star | Mục tiêu | 🚨 Ngưỡng nguy hiểm |
|-------|-----------|----------|---------------------|
| T1 | Onboarding completion | 70% | < 50% |
| T2 | D30 Retention | 30% | < 20% |
| T2 | Monthly recalibration rate | 40% | < 20% |
| T3 | Premium conversion | 3–5% | < 2% |
| T4 | MRR | > 20 triệu | Stagnant |
| T5 | MAU growth | 2x vs T3 | < 1.5x |

**Trust Metrics (đặc thù sản phẩm này):**
| Metric | Mục tiêu |
|--------|---------|
| Monthly recalibration rate | ≥ 40% MAU |
| Plan Reliability avg | ≥ 60% sau T2 |
| Scenario Calculator usage | ≥ 50% MAU |
| Viral card shares | ≥ 10% MAU |

---

## 🚀 Beta Launch Plan

**Target:** 100–200 beta users (Closed Testing)
**Channel:** TestFlight (iOS) + Google Play Closed Testing (Android)
**Thời điểm:** Cuối Sprint 2 (tuần 4)

**Recruitment:**
- Facebook groups tài chính cá nhân VN
- LinkedIn (working professionals)
- Bạn bè, đồng nghiệp của cả 2 founder
- Discord/Telegram communities

**Beta Feedback Loop:**
- Typeform survey sau 7 ngày dùng
- Mixpanel session recording (opt-in)
- In-app feedback button (shake to report)

---

## ⚠️ Next Steps Ngay Bây Giờ

1️⃣ **Hôm nay:** Co-founder bắt đầu Phase 0A — Flutter init + Supabase project  
2️⃣ **Tuần này:** Founder finalize Figma design system + Copy writing  
3️⃣ **Cuối tuần -1:** `/design` — Review DB Schema + Calculation Engine trước khi code  
