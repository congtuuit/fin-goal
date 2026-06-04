import 'package:fin_goal/features/cashflow_game/domain/entities/occupation.dart';

/// 12 nghề nghiệp với số liệu cân bằng để game kéo dài 20-40 lượt
/// Đơn vị: VND (không dùng digit separator để tránh lỗi build)
const List<Occupation> occupations = [
  // ── EASY (1-2 sao) ───────────────────────────────────────────────────────

  Occupation(
    id: 'farmer',
    name: 'Nông Dân',
    emoji: '👨‍🌾',
    description: 'Thu nhập thấp, chi phí rất thấp. Điều kiện thắng dễ nhất — cần thu nhập thụ động > 4.5 triệu/tháng.',
    category: OccupationCategory.trade,
    monthlySalary: 7000000,       // 7 triệu
    monthlyExpenses: 4000000,     // 4 triệu sinh hoạt
    initialCash: 20000000,        // 20 triệu khởi đầu
    initialDebt: 10000000,        // 10 triệu nợ
    monthlyLoanPayment: 500000,   // 500k/tháng trả nợ
    initialCreditScore: 580,
    difficulty: 'easy',
    difficultyStars: 1,
    // CF = 7M - 4M - 0.5M = 2.5M/tháng | Win: passive > 4.5M
  ),

  Occupation(
    id: 'driver',
    name: 'Tài Xế',
    emoji: '🚗',
    description: 'Lương thấp nhưng chi phí vừa phải. Cần thu nhập thụ động > 6.3 triệu/tháng để thoát Rat Race.',
    category: OccupationCategory.trade,
    monthlySalary: 9000000,       // 9 triệu
    monthlyExpenses: 5500000,     // 5.5 triệu
    initialCash: 25000000,        // 25 triệu
    initialDebt: 15000000,        // 15 triệu
    monthlyLoanPayment: 800000,   // 800k
    initialCreditScore: 600,
    difficulty: 'easy',
    difficultyStars: 1,
    // CF = 9M - 5.5M - 0.8M = 2.7M/tháng | Win: passive > 6.3M
  ),

  Occupation(
    id: 'teacher',
    name: 'Giáo Viên',
    emoji: '👨‍🏫',
    description: 'Lương ổn định, ít nợ. Thích hợp cho người mới. Cần thu nhập thụ động > 8.5 triệu/tháng.',
    category: OccupationCategory.professional,
    monthlySalary: 12000000,      // 12 triệu
    monthlyExpenses: 7000000,     // 7 triệu
    initialCash: 30000000,        // 30 triệu
    initialDebt: 30000000,        // 30 triệu
    monthlyLoanPayment: 1500000,  // 1.5 triệu
    initialCreditScore: 650,
    difficulty: 'easy',
    difficultyStars: 2,
    // CF = 12M - 7M - 1.5M = 3.5M/tháng | Win: passive > 8.5M
  ),

  Occupation(
    id: 'nurse',
    name: 'Y Tá',
    emoji: '👩‍⚕️',
    description: 'Lương khá, chi phí vừa phải. Cân bằng tốt. Cần thu nhập thụ động > 11 triệu/tháng.',
    category: OccupationCategory.professional,
    monthlySalary: 15000000,      // 15 triệu
    monthlyExpenses: 9000000,     // 9 triệu
    initialCash: 35000000,        // 35 triệu
    initialDebt: 40000000,        // 40 triệu
    monthlyLoanPayment: 2000000,  // 2 triệu
    initialCreditScore: 680,
    difficulty: 'easy',
    difficultyStars: 2,
    // CF = 15M - 9M - 2M = 4M/tháng | Win: passive > 11M
  ),

  // ── MEDIUM (3 sao) ───────────────────────────────────────────────────────

  Occupation(
    id: 'restaurant_manager',
    name: 'Quản Lý Nhà Hàng',
    emoji: '👨‍🍳',
    description: 'Thu nhập trung bình, có kinh nghiệm kinh doanh. Cần thu nhập thụ động > 13.5 triệu/tháng.',
    category: OccupationCategory.business,
    monthlySalary: 17000000,      // 17 triệu
    monthlyExpenses: 11000000,    // 11 triệu
    initialCash: 40000000,        // 40 triệu
    initialDebt: 50000000,        // 50 triệu
    monthlyLoanPayment: 2500000,  // 2.5 triệu
    initialCreditScore: 640,
    difficulty: 'medium',
    difficultyStars: 2,
    // CF = 17M - 11M - 2.5M = 3.5M/tháng | Win: passive > 13.5M
  ),

  Occupation(
    id: 'accountant',
    name: 'Kế Toán',
    emoji: '🧮',
    description: 'Hiểu về số liệu, điểm tín dụng tốt. Cần thu nhập thụ động > 16 triệu/tháng để thoát Rat Race.',
    category: OccupationCategory.professional,
    monthlySalary: 20000000,      // 20 triệu
    monthlyExpenses: 13000000,    // 13 triệu
    initialCash: 45000000,        // 45 triệu
    initialDebt: 60000000,        // 60 triệu
    monthlyLoanPayment: 3000000,  // 3 triệu
    initialCreditScore: 700,
    difficulty: 'medium',
    difficultyStars: 3,
    // CF = 20M - 13M - 3M = 4M/tháng | Win: passive > 16M
  ),

  Occupation(
    id: 'small_business',
    name: 'Chủ Tiệm Nhỏ',
    emoji: '🏪',
    description: 'Thu nhập biến động, thách thức quản lý dòng tiền. Cần thu nhập thụ động > 18 triệu/tháng.',
    category: OccupationCategory.business,
    monthlySalary: 22000000,      // 22 triệu
    monthlyExpenses: 14000000,    // 14 triệu
    initialCash: 50000000,        // 50 triệu
    initialDebt: 80000000,        // 80 triệu
    monthlyLoanPayment: 4000000,  // 4 triệu
    initialCreditScore: 660,
    difficulty: 'medium',
    difficultyStars: 3,
    // CF = 22M - 14M - 4M = 4M/tháng | Win: passive > 18M
  ),

  Occupation(
    id: 'engineer',
    name: 'Kỹ Sư',
    emoji: '👷',
    description: 'Lương tốt nhưng nợ học phí đáng kể. Cần thu nhập thụ động > 20.5 triệu/tháng.',
    category: OccupationCategory.technical,
    monthlySalary: 25000000,      // 25 triệu
    monthlyExpenses: 16000000,    // 16 triệu
    initialCash: 60000000,        // 60 triệu
    initialDebt: 100000000,       // 100 triệu
    monthlyLoanPayment: 4500000,  // 4.5 triệu
    initialCreditScore: 720,
    difficulty: 'medium',
    difficultyStars: 3,
    // CF = 25M - 16M - 4.5M = 4.5M/tháng | Win: passive > 20.5M
  ),

  Occupation(
    id: 'software_dev',
    name: 'Lập Trình Viên',
    emoji: '💻',
    description: 'Lương cao trong kỹ thuật. Có thể tận dụng kỹ năng tạo thu nhập thụ động > 23 triệu/tháng.',
    category: OccupationCategory.technical,
    monthlySalary: 30000000,      // 30 triệu
    monthlyExpenses: 19000000,    // 19 triệu
    initialCash: 70000000,        // 70 triệu
    initialDebt: 90000000,        // 90 triệu
    monthlyLoanPayment: 4000000,  // 4 triệu
    initialCreditScore: 730,
    difficulty: 'medium',
    difficultyStars: 3,
    // CF = 30M - 19M - 4M = 7M/tháng | Win: passive > 23M
  ),

  // ── HARD (4-5 sao) ───────────────────────────────────────────────────────

  Occupation(
    id: 'lawyer',
    name: 'Luật Sư',
    emoji: '⚖️',
    description: 'Lương rất cao nhưng học phí và chi phí sống cũng rất cao. Cần passive > 37 triệu/tháng.',
    category: OccupationCategory.professional,
    monthlySalary: 45000000,      // 45 triệu
    monthlyExpenses: 30000000,    // 30 triệu
    initialCash: 100000000,       // 100 triệu
    initialDebt: 200000000,       // 200 triệu
    monthlyLoanPayment: 7000000,  // 7 triệu
    initialCreditScore: 750,
    difficulty: 'hard',
    difficultyStars: 4,
    // CF = 45M - 30M - 7M = 8M/tháng | Win: passive > 37M
  ),

  Occupation(
    id: 'doctor',
    name: 'Bác Sĩ',
    emoji: '👨‍⚕️',
    description: 'Lương cao nhất nhóm nhưng nợ y khoa khổng lồ. Cực kỳ thách thức. Passive > 45 triệu/tháng.',
    category: OccupationCategory.professional,
    monthlySalary: 55000000,      // 55 triệu
    monthlyExpenses: 37000000,    // 37 triệu
    initialCash: 120000000,       // 120 triệu
    initialDebt: 350000000,       // 350 triệu
    monthlyLoanPayment: 8000000,  // 8 triệu
    initialCreditScore: 780,
    difficulty: 'hard',
    difficultyStars: 4,
    // CF = 55M - 37M - 8M = 10M/tháng | Win: passive > 45M
  ),

  Occupation(
    id: 'pilot',
    name: 'Phi Công',
    emoji: '✈️',
    description: 'Lương cao nhất, nợ đào tạo và chi phí đắt đỏ. Chỉ dành cho chuyên gia. Passive > 52 triệu/tháng.',
    category: OccupationCategory.professional,
    monthlySalary: 65000000,      // 65 triệu
    monthlyExpenses: 42000000,    // 42 triệu
    initialCash: 150000000,       // 150 triệu
    initialDebt: 300000000,       // 300 triệu
    monthlyLoanPayment: 10000000, // 10 triệu
    initialCreditScore: 770,
    difficulty: 'expert',
    difficultyStars: 5,
    // CF = 65M - 42M - 10M = 13M/tháng | Win: passive > 52M
  ),
];
