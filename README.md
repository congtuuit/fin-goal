# Financial Scenario Simulator

> "Mô phỏng tài chính dựa trên dữ liệu bạn cung cấp"

---

## Monorepo Structure

```
fin-goal/
├── mobile/          # Flutter app (iOS + Android)
├── supabase/        # Backend (Supabase + Edge Functions)
├── docs/            # Documentation & product specs
├── scripts/         # Automation scripts
└── .github/         # CI/CD workflows
```

## Quick Start

### Prerequisites
- Flutter 3.19+
- Dart 3.3+
- Supabase CLI
- Android Studio / Xcode

### Setup

```bash
# 1. Clone
git clone https://github.com/[org]/fin-goal.git
cd fin-goal

# 2. Setup Flutter
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Environment variables
cp .env.example .env
# Edit .env với Supabase URL + Anon Key

# 4. Start local Supabase
cd ../supabase
supabase start
supabase db push

# 5. Run app (dev flavor)
cd ../mobile
flutter run --flavor dev -t lib/main_dev.dart
```

## Architecture

**Pattern:** Clean Architecture + Feature-first  
**State:** Riverpod 2.x  
**Navigation:** Go Router  
**DI:** get_it + injectable  
**Backend:** Supabase (Auth + PostgreSQL + Edge Functions)  
**Local DB:** Isar (offline-first)

### Key Principle: SIMULATE, not PREDICT

All results displayed as: *"Based on the data you provided"*  
Never claim certainty. Always show confidence ranges.

## Docs

- [Product DRAFT](./docs/DRAFT.md)
- [Implementation Plan](./docs/implementation_plan.md)
- [Project Structure](./docs/project_structure.md)
- [Calculation Engine](./docs/calculation-engine.md)
- [API Reference](./docs/api.md)

## Team

| Role | Responsibility |
|------|---------------|
| Founder (Product) | UI/UX, Copy, Analytics, AI prompts |
| Co-founder (Tech) | Architecture, Infra, Core Engine, DevOps |

---

*Beta Closed — TestFlight + Google Play Beta*
