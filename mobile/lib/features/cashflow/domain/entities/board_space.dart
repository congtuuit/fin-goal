enum SpaceType {
  opportunity, // Small Deal / Big Deal
  doodad,      // Tiêu sản bất ngờ (mua sắm, sửa xe...)
  market,      // Thị trường (Bán tài sản)
  paycheck,    // Nhận lương (Cộng cashflow vào tiền mặt)
  baby,        // Thêm con (Tăng chi phí)
  downsize,    // Thất nghiệp (Mất lượt, mất tiền)
  charity      // Từ thiện
}

// Bàn cờ Cashflow tĩnh gồm 24 ô
// Người chơi di chuyển vòng tròn qua các ô này.
const List<SpaceType> ratRaceBoard = [
  SpaceType.paycheck,    // 0: Start / Paycheck
  SpaceType.opportunity, // 1
  SpaceType.doodad,      // 2
  SpaceType.opportunity, // 3
  SpaceType.charity,     // 4
  SpaceType.opportunity, // 5
  SpaceType.paycheck,    // 6
  SpaceType.opportunity, // 7
  SpaceType.market,      // 8
  SpaceType.doodad,      // 9
  SpaceType.opportunity, // 10
  SpaceType.baby,        // 11
  SpaceType.paycheck,    // 12
  SpaceType.opportunity, // 13
  SpaceType.doodad,      // 14
  SpaceType.opportunity, // 15
  SpaceType.market,      // 16
  SpaceType.opportunity, // 17
  SpaceType.paycheck,    // 18
  SpaceType.opportunity, // 19
  SpaceType.doodad,      // 20
  SpaceType.opportunity, // 21
  SpaceType.downsize,    // 22
  SpaceType.opportunity, // 23
];
