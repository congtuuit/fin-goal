# Kế Hoạch Kiểm Thử (Test Plan) & Bộ Test Cases

**Dự án:** Fin-Goal Mobile App  
**Nền tảng:** Flutter (iOS/Android)  
**Trạng thái:** Kế hoạch (Chưa triển khai code)

---

## 1. Mục tiêu Kiểm thử
- **Đảm bảo tính ổn định:** Core flows (Đăng nhập, Tạo mục tiêu, Check-in) phải hoạt động mượt mà, không gián đoạn.
- **Tính chính xác:** Các logic tính toán (Engine) tài chính, lạm phát, dòng tiền phải luôn chuẩn xác.
- **Ngăn chặn lỗi hồi quy (Regression bugs):** Tránh trường hợp sửa tính năng A lại làm hỏng giao diện tính năng B.

## 2. Phân loại & Phạm vi (Scope)
- **Unit Test:** Dành cho các core logic (VD: `ScenarioEngine`, tính toán `MonthlyRecord`, hàm chuyển đổi tiền tệ).
- **Widget Test:** Dành cho các UI Component độc lập, dễ tái sử dụng (VD: `GoalCard`, `TimelineCard`, Slider).
- **Integration Test (E2E Test):** Dành cho thao tác người dùng thật qua từng luồng màn hình hoàn chỉnh.

---

## 3. Bộ Test Cases (End-to-End UI Flows)

Dựa trên hệ thống định tuyến (Routing) hiện tại của App, dưới đây là bộ Test Cases cốt lõi:

### Phân hệ 1: Xác thực & Khởi tạo (Auth & Onboarding)
| ID | Tên Test Case | Các bước giả lập | Kết quả mong đợi |
|---|---|---|---|
| TC-AUTH-01 | Đăng nhập hợp lệ | 1. Mở app ở trang `/login`<br>2. Nhập thông tin hợp lệ<br>3. Bấm "Đăng nhập" | Vào trang `/home` (nếu đã xong onboarding) hoặc `/onboarding`. |
| TC-AUTH-02 | Hoàn thành Onboarding | 1. Ở trang `/onboarding`<br>2. Trả lời các câu hỏi khảo sát<br>3. Bấm Hoàn tất | Lưu trạng thái `hasCompletedOnboarding=true`, tự động chuyển qua `/home`. |

### Phân hệ 2: Danh sách Mục tiêu (Home/Goals)
| ID | Tên Test Case | Các bước giả lập | Kết quả mong đợi |
|---|---|---|---|
| TC-GOAL-01 | Tải danh sách rỗng | 1. Đăng nhập acc mới tinh<br>2. Mở `/home` | Hiển thị màn hình "Chưa có mục tiêu", có nút điều hướng kêu gọi tạo mới. |
| TC-GOAL-02 | Tạo mục tiêu thành công | 1. Bấm nút "Tạo mục tiêu"<br>2. Chọn loại mục tiêu<br>3. Điền các con số (tiền, kỳ hạn)<br>4. Lưu | Quay về Home, Card mục tiêu hiển thị đúng tiến độ % và con số đã nhập. |
| TC-GOAL-03 | Giới hạn Free User | 1. Acc Free đã có >=1 mục tiêu<br>2. Bấm nút "Tạo thêm" | Hiển thị ngay màn hình Paywall chặn lại. |

### Phân hệ 3: Kịch bản & Check-in (Scenario Dashboard)
| ID | Tên Test Case | Các bước giả lập | Kết quả mong đợi |
|---|---|---|---|
| TC-SCEN-01 | Mở Dashboard mục tiêu | 1. Tại Home, bấm vào Card mục tiêu | Chuyển qua `/home/dashboard`, thấy Timeline dự kiến hoàn thành. |
| TC-SCEN-02 | Tương tác Slider Tiết kiệm | 1. Tại Dashboard, kéo thanh trượt "Tiết kiệm mỗi tháng" | Con số dự kiến hoàn thành (Tháng/Năm) phải thay đổi theo real-time. |
| TC-SCEN-03 | Nhập Check-in tháng | 1. Bấm "Check-in tháng này"<br>2. Gõ số tiền tiết kiệm<br>3. Bấm Xác nhận | Báo thành công (hiện dấu tick), quay lại Dashboard, tổng tiền Tích lũy tăng lên tương ứng. |
| TC-SCEN-04 | Trải nghiệm What-if | 1. Bấm "Thử kịch bản What-if"<br>2. Thay đổi thanh Lạm phát/Lợi nhuận | Biểu đồ (hoặc số liệu) phản hồi sự khác biệt giữa Kế hoạch và Thực tế. |

### Phân hệ 4: Nâng cấp Premium & Profile
| ID | Tên Test Case | Các bước giả lập | Kết quả mong đợi |
|---|---|---|---|
| TC-PREM-01 | Xem Paywall | 1. Bấm icon Nâng cấp/Kim cương | Hiển thị `PaywallPage`, show giá trị gói Premium. |
| TC-PREM-02 | Mua gói thành công | 1. Chọn mua gói<br>2. Giả lập thanh toán qua `PaymentPage` | Cập nhật cờ `isPremium=true`, các giới hạn chức năng được gỡ bỏ. |
| TC-PROF-01 | Sửa Profile | 1. Vào `/profile`<br>2. Đổi tên user | Thông tin mới hiển thị ngay lập tức không cần restart app. |

### Phân hệ 5: Cashflow Board Game (Tiện ích)
| ID | Tên Test Case | Các bước giả lập | Kết quả mong đợi |
|---|---|---|---|
| TC-GAME-01 | Mở Game không lỗi | 1. Chọn vào `CashflowBoardGame` | Màn hình load thành công, không gặp exception hoặc crash. |

---

## 4. Kế hoạch Triển khai (Khi cần Code Thực tế)

Khi bạn muốn bắt đầu làm, chúng ta sẽ đi theo trình tự sau để tối ưu thời gian:

1. **Bước 1: Viết Unit Test cho Core Logic (Ưu tiên nhất)**
   - Test class `ScenarioEngine` (bỏ qua UI, chỉ truyền số liệu đầu vào và kiểm tra số liệu đầu ra để chắc chắn App tính toán tài chính không bao giờ sai).
2. **Bước 2: Cài đặt Framework E2E**
   - Import `integration_test` hoặc `patrol`. Setup chạy thử mở app tự động.
3. **Bước 3: Viết Automation script cho 'Happy Path'**
   - Viết luồng TC-AUTH-01 -> TC-GOAL-02 -> TC-SCEN-03 (Đây là 3 luồng quan trọng nhất mang lại value cho App).
4. **Bước 4: Viết Edge Cases & CI/CD**
   - Cài Github Actions để tự động test các trường hợp báo lỗi, nhập sai định dạng.
