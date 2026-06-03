# Calculation Engine — Technical Documentation

## Triết lý cốt lõi

> **SIMULATE, không PREDICT.**
>
> App KHÔNG nói: *"Bạn sẽ đạt mục tiêu sau 26 tháng."*
>
> App NÓI: *"Dựa trên dữ liệu bạn cung cấp, kịch bản dự kiến là 27 tháng."*

## Formula

### Expected Case (Dự kiến)

```
remaining = target_amount - current_savings
expected_months = ceil(remaining / monthly_saving)
```

### Best Case (Tốt nhất)

```
best_months = floor(expected_months × (1 - variance_buffer))
variance_buffer default = 0.15 (15%)
→ best = expected × 0.85
```

### Worst Case (Xấu nhất)

```
worst_months = ceil(expected_months × (1 + variance_buffer × 2))
→ worst = expected × 1.30
```

### Plan Reliability Score

Bắt đầu ở 40% — tăng dần khi user cung cấp dữ liệu thực tế.

```
base = 40.0

+ months_with_actual_data × 5.0   // +5% mỗi tháng có data
+ 10.0 if avg_variance < 0.10     // Bonus: rất consistent
- 5.0  if avg_variance > 0.30     // Penalty: hay lệch kế hoạch

reliability = clamp(base, 0.0, 95.0)  // Max 95% — never 100%
```

**Lý do không bao giờ đạt 100%:** Chúng ta trung thực về giới hạn của hệ thống.

## What-If Impact Calculation

```
impact_months = calculate(input_without_purchase).expectedMonths
              - calculate(input_with_purchase_deducted).expectedMonths
```

Ví dụ:
- Hiện có: 10 triệu
- Mục tiêu: 100 triệu
- Tiết kiệm: 3 triệu/tháng
- Muốn mua iPhone: 35 triệu

```
Without: (100M - 10M) / 3M = 30 tháng
With:    (100M - (10M - 35M)) / 3M  →  cần 125M, còn lại 91.67 tháng
Impact: 92 - 30 = 62 tháng  (vì bị âm current_savings → clamp về 0)
→ Thực chất: 35M / 3M ≈ 12 tháng chậm hơn
```

## File Location

```
mobile/lib/features/scenarios/engine/
├── scenario_engine.dart         # Main engine class
├── scenario_input.dart          # Input model
└── scenario_result.dart         # Output model

mobile/test/unit/features/scenarios/engine/
└── scenario_engine_test.dart    # Unit tests
```

## Testing

```bash
cd mobile
flutter test test/unit/features/scenarios/engine/
```

Expected: 5/5 tests pass.
