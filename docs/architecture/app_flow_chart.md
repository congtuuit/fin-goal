# 🗺️ Biểu đồ Luồng Ứng dụng (App Flow Chart)

Ngày cập nhật: 03/06/2026
Dự án: **fin-goal (Financial Simulator App)**

Dưới đây là biểu đồ mô tả luồng điều hướng và vòng đời (User Journey) của người dùng trong ứng dụng. Biểu đồ này phản ánh trực tiếp logic điều hướng được thiết lập trong `app_router.dart`.

```mermaid
flowchart TB
    %% Định nghĩa Styles cho các nút
    classDef startEnd fill:#ECEFF1,stroke:#37474F,stroke-width:2px,color:#263238;
    classDef auth fill:#E1F5FE,stroke:#0288D1,stroke-width:2px,color:#01579B;
    classDef onboarding fill:#FFF3E0,stroke:#F57C00,stroke-width:2px,color:#E65100;
    classDef core fill:#E8F5E9,stroke:#388E3C,stroke-width:2px,color:#1B5E20;
    classDef premium fill:#FCE4EC,stroke:#D81B60,stroke-width:2px,color:#880E4F;
    classDef database fill:#EDE7F6,stroke:#5E35B1,stroke-width:2px,color:#4A148C;

    subgraph Entry ["🚀 Khởi Chạy Ứng Dụng"]
        Start([📱 Mở Ứng dụng]) ::: startEnd
        Splash["⌛ Màn hình Splash <br/> (Kiểm tra Session)"] ::: startEnd
    end

    subgraph Authentication ["🔐 Xác Thực Người Dùng"]
        Login["🔑 Màn hình Đăng nhập / Đăng ký <br/> (LoginPage)"] ::: auth
        SupabaseAuth[("☁️ Supabase Auth <br/> (Quản lý Session)")] ::: database
    end

    subgraph Setup ["📋 Khảo Sát Ban Đầu"]
        Onboarding["📊 Khảo sát Tài chính <br/> (OnboardingPage)"] ::: onboarding
    end

    subgraph CoreApp ["💡 Kịch Bản Tài Chỉ (Core)"]
        Dashboard["🏠 Bảng điều khiển Kịch bản <br/> (ScenarioDashboardPage)"] ::: core
        GoalSelection["🎯 Chọn Mục tiêu Tài chính <br/> (GoalSelectionPage)"] ::: core
        MonthlyCheckin["📅 Cập nhật Tiến độ Tháng <br/> (MonthlyCheckinPage)"] ::: core
        WhatIf["🔮 Mô phỏng Tương lai & AI <br/> (WhatIfPage)"] ::: core
    end

    subgraph PremiumStore ["💎 Gói Nâng Cấp"]
        Paywall["💳 Nâng cấp Premium <br/> (PaywallPage)"] ::: premium
    end

    %% Luồng điều hướng (Flow)
    Start --> Splash
    
    %% Rẽ nhánh từ Splash
    Splash -->|Chưa đăng nhập| Login
    Splash -->|"Đã đăng nhập <br/> (Chưa làm khảo sát)"| Onboarding
    Splash -->|"Đã đăng nhập <br/> (Đã xong khảo sát)"| Dashboard
    
    %% Luồng Auth
    Login -->|Gửi Email / Google| SupabaseAuth
    SupabaseAuth -->|Xác thực thành công| Splash
    
    %% Luồng Onboarding
    Onboarding -->|Hoàn thành khảo sát| Dashboard
    
    %% Điều hướng từ Dashboard
    Dashboard --> GoalSelection
    Dashboard --> MonthlyCheckin
    Dashboard --> WhatIf
    Dashboard --> Paywall
    
    %% Tương tác Premium
    WhatIf -.->|Yêu cầu tính năng nâng cao| Paywall
    Paywall -->|Thanh toán thành công| WhatIf
```

## 📝 Giải thích chi tiết các nút thắt:
1. **SplashPage**: Đóng vai trò là trạm trung chuyển (Router Guard). Người dùng không bao giờ ở lại màn hình này quá lâu. Trạm sẽ kiểm tra trạng thái bộ nhớ đệm (Token) và trạng thái Onboarding.
2. **OnboardingPage**: Bắt buộc đối với tài khoản mới. Nếu người dùng tắt app giữa chừng lúc đang làm khảo sát, lần sau mở lên `SplashPage` sẽ tự động chuyển hướng họ về lại đây.
3. **ScenarioDashboardPage**: Màn hình gốc (Home). Từ đây người dùng phân nhánh đi làm các tác vụ mô phỏng tài chính.
4. **PaywallPage**: Khóa chặn các tính năng trả phí (ví dụ như xem giải thích sâu từ AI trong màn hình What-If). Có thể được gọi từ nhiều nơi trong ứng dụng.

