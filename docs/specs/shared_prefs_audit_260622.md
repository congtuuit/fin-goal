# 🔐 Auth & Data Isolation — SharedPreferences Audit

> **Ngày thực hiện:** 2026-06-22  
> **Lý do:** QC phát hiện dữ liệu bị rò rỉ giữa các tài khoản khi đăng xuất/xóa tài khoản  
> **Trạng thái:** ✅ Đã fix hoàn toàn

---

## 📋 Bảng Audit Toàn Bộ SharedPreferences Keys

| Key | Lưu ở đâu | Loại | Guest delete | Online delete | Ghi chú |
|-----|-----------|------|:---:|:---:|---------|
| `logged_in_user` | `AuthRepositoryImpl` | 🔴 User | ✅ | ✅ | JSON serialized AppUser |
| `local_username` | `AuthRepositoryImpl`, `LocalAuthRepositoryImpl` | 🔴 User | ✅ | ✅ | Tên hiển thị Guest |
| `has_logged_in_with_google` | `AuthRepositoryImpl` | 🔴 User | ~~❌~~ → ✅ | ✅ | Flag google auth |
| `onboarding_completed` | `ProfileRepositoryImpl`, `LocalProfileRepositoryImpl` | 🔴 User | ✅ | ~~❌~~ → ✅ | **Bug gốc của issue "Chưa có profile"** |
| `local_financial_profile` | `LocalProfileRepositoryImpl` | 🔴 User | ✅ | ✅ | Guest profile JSON |
| `local_goals` | `LocalGoalRepositoryImpl` | 🔴 User | ✅ | ✅ | Guest goals list |
| `local_records` | `LocalRecordRepositoryImpl` | 🔴 User | ✅ | ✅ | Guest monthly records |
| `local_scenarios` | `LocalScenarioRepositoryImpl` | 🔴 User | ✅ | ✅ | Guest scenario queries |
| `cashflow_game_v2_{userId}` | `GameRepository` | 🔴 User | ~~❌~~ → ✅ | ~~❌~~ → ✅ | Game state keyed by userId |
| `coach_advice_{goalId}_{date}` | `CoachRepository` | 🔴 User | ~~❌~~ → ✅ | ~~❌~~ → ✅ | AI advice cache |
| `coach_advice_time_{goalId}_{date}` | `CoachRepository` | 🔴 User | ~~❌~~ → ✅ | ~~❌~~ → ✅ | Cache timestamp |
| `coach_tone` | `CoachToneNotifier` | 🔴 User | ~~❌~~ → ✅ | ~~❌~~ → ✅ | Tone preference per user |
| `ai_provider` | `DirectClientAiService` | 🟢 App setting | 🟢 Giữ | 🟢 Giữ | `gemini` / `openai` |
| `ai_api_key` | `DirectClientAiService` | 🟢 App setting | 🟢 Giữ | 🟢 Giữ | User-configured API key |
| `ai_model` | `DirectClientAiService` | 🟢 App setting | 🟢 Giữ | 🟢 Giữ | Model name string |
| `sfx_muted` | `AudioProvider` | 🟢 App setting | 🟢 Giữ | 🟢 Giữ | Sound FX toggle |
| `has_seen_welcome` | `AuthProvider` | 🟢 App setting | 🟢 Giữ | 🟢 Giữ | Chỉ show Welcome 1 lần |

---

## 🐛 Bugs Được Fix

### Bug #1: Data persistence giữa accounts (Riverpod stale state)
**Mô tả:** Đăng nhập Google → tạo goal → đăng xuất → đăng nhập account khác → thấy data của account cũ.

**Root cause:** Các Notifier với `keepAlive: true` dùng `ref.read` trong `build()`, không reactive với auth state change.

**Fix:** Thêm `ref.watch(repositoryProvider)` trong `build()` của tất cả Notifiers:

| File | Notifier | Fix |
|------|----------|-----|
| `goal_provider.dart` | `GoalsNotifier` | Watch `goalRepositoryProvider` |
| `scenario_provider.dart` | `ScenarioQueriesNotifier` | Watch `scenarioRepositoryProvider` |
| `scenario_provider.dart` | `RecordsNotifier` | Watch `recordRepositoryProvider` |
| `scenario_provider.dart` | `hasCheckedInThisMonth` | Watch `recordRepositoryProvider` |
| `profile_provider.dart` | `ProfileNotifier` | Watch `profileRepositoryProvider` |
| `game_provider.dart` | `CashflowGameNotifier` | Watch `currentUserProvider` |

---

### Bug #2: Guest logout giữ data, Guest delete xóa sai
**Mô tả:** Guest đăng xuất phải giữ data (correct). Guest xóa tài khoản phải xóa sạch data của guest.

**Root cause:** `LocalAuthRepositoryImpl.deleteAccount()` gọi `_prefs.clear()` — xóa toàn bộ kể cả app settings.

**Fix:** Thay bằng selective key removal trong cả `LocalAuthRepositoryImpl` và `AuthRepositoryImpl`.

---

### Bug #3: Login Google lại sau khi xóa tài khoản → "Chưa có profile"
**Mô tả:** Delete Google account → re-login same email → tạo goal → click vào goal → crash "Chưa có profile".

**Root cause (2 tầng):**
1. `deleteAccount()` online không xóa `onboarding_completed` từ SharedPreferences
2. `hasCompletedOnboarding()` check local flag TRƯỚC Supabase — nếu local = `true` → skip onboarding → vào dashboard → `profile == null` → crash

**Fix:**
```
AuthRepositoryImpl.deleteAccount() → _clearAllUserData(userId) → xóa onboarding_completed
settings_page.dart → ref.invalidate(hasCompletedOnboardingProvider) sau delete thành công
```

---

## 🏗️ Giải pháp Kiến trúc

### Helper `_clearAllUserData(userId)` — `AuthRepositoryImpl`

Thay thế các lệnh `prefs.remove()` rải rác bằng 1 hàm tập trung:

```dart
Future<void> _clearAllUserData(String userId) async {
  // Auth & identity
  prefs.remove('logged_in_user');
  prefs.remove('local_username');
  prefs.remove('has_logged_in_with_google');
  // Onboarding
  prefs.remove('onboarding_completed');
  // Goal / scenario / profile (guest data)
  prefs.remove('local_goals');
  prefs.remove('local_records');
  prefs.remove('local_scenarios');
  prefs.remove('local_financial_profile');
  // Cashflow game state (keyed by userId)
  prefs.remove('cashflow_game_v2_$userId');
  // AI Coach cache (all goalId-prefixed entries)
  for (k in prefs.getKeys().where(k.startsWith('coach_advice_'))) prefs.remove(k);
  // Coach tone preference
  prefs.remove('coach_tone');
  
  // ✅ PRESERVED (App-wide settings):
  // ai_provider, ai_api_key, ai_model, sfx_muted, has_seen_welcome
}
```

---

## ✅ Test Cases QC

| # | Scenario | Expected | Status |
|---|----------|----------|--------|
| 1 | Login Google A → goal → logout → login Google B | Dashboard B: dữ liệu của B | Đã fix |
| 2 | Login Google → goal → delete account → login Google lại | Hiển thị màn hình Onboarding | Đã fix |
| 3 | Guest tạo data → logout | Data vẫn còn khi login lại | Không thay đổi ✅ |
| 4 | Guest tạo data → delete account | Data bị xóa hoàn toàn (game, coach cache, goals) | Đã fix |
| 5 | Delete account → App settings còn nguyên | `ai_provider`, `sfx_muted`, etc. vẫn còn | Đã fix |

---

## 📁 Files Đã Thay Đổi

| File | Loại thay đổi |
|------|---------------|
| `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart` | Thêm `_clearAllUserData()`, fix Guest branch, fix Online branch |
| `mobile/lib/features/auth/data/repositories/local_auth_repository_impl.dart` | Mở rộng `deleteAccount()` xóa game + coach cache |
| `mobile/lib/features/auth/presentation/providers/auth_provider.dart` | (không đổi — invalidation xử lý ở UI layer) |
| `mobile/lib/features/profile/presentation/pages/settings_page.dart` | Thêm `ref.invalidate(hasCompletedOnboardingProvider)` sau delete |
| `mobile/lib/features/goals/presentation/providers/goal_provider.dart` | Watch `goalRepositoryProvider` trong `build()` |
| `mobile/lib/features/scenarios/presentation/providers/scenario_provider.dart` | Watch repository providers trong 3 notifiers |
| `mobile/lib/features/profile/presentation/providers/profile_provider.dart` | Watch `profileRepositoryProvider` trong `build()` |
| `mobile/lib/features/cashflow_game/presentation/providers/game_provider.dart` | Watch `currentUserProvider` trong `build()` |
