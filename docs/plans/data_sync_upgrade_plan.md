# Kế hoạch nâng cấp & Tối ưu hóa cơ chế đồng bộ hóa dữ liệu (Offline to Online)

Tài liệu này lưu trữ các điểm hạn chế của hệ thống đồng bộ hóa hiện tại và đề xuất lộ trình kỹ thuật chi tiết để nâng cấp trong tương lai nhằm tăng tính tin cậy, hiệu năng và cải thiện trải nghiệm người dùng.

---

## 🔍 Đánh giá hệ thống hiện tại (AS-IS)

Hệ thống hiện tại đồng bộ hóa dữ liệu Guest cục bộ bằng cách gửi các request HTTP tuần tự lên Supabase (Sync Profile ➡️ Loops sync Goals ➡️ Sync Records ➡️ Sync Scenarios).
* **Ưu điểm**: Đơn giản, triển khai nhanh, dễ kiểm thử ở quy mô nhỏ.
* **Nhược điểm lớn**:
  1. **Không có Database Transaction**: Mất mạng giữa chừng gây tình trạng đồng bộ dở dang (Goal đã lên nhưng Record chưa lên), dễ dẫn đến trùng lặp dữ liệu (Duplicate data) khi sync lại.
  2. **Hiệu năng kém (N+1 Connection)**: Vòng lặp `for` đồng bộ từng Goal tạo ra nhiều network calls tuần tự gây trễ lớn.
  3. **Hạn chế của SharedPreferences**: Việc lưu trữ dữ liệu quan hệ có cấu trúc trong file phẳng Key-Value của SharedPreferences không tối ưu khi quy mô bản ghi tăng lên.
  4. **Chưa giải quyết xung đột (Conflict Resolution)**: Đăng nhập vào tài khoản Google đã có sẵn dữ liệu online sẽ gây chồng chéo hoặc ghi đè không kiểm soát.

---

## 🛠️ Lộ trình Nâng cấp & Tối ưu hóa (TO-BE)

### Giai đoạn 1: Tối ưu hóa hiệu năng & Tính nguyên tử (Performance & Atomicity)

#### 1. Client-Side UUID Generation (Loại bỏ ID Auto-Increment cục bộ)
* **Giải pháp**: Thay vì dùng ID tự tăng cục bộ dạng số hoặc text thường, sử dụng package `uuid` để tự sinh khóa chính UUID chuẩn ngay tại local khi tạo mới Goal/Record.
* **Lợi ích**: Khi đồng bộ, client không cần chờ Supabase chèn bản ghi và trả về ID để làm bản đồ mapping khóa ngoại nữa. Dữ liệu có thể được insert đồng thời.

#### 2. Đồng bộ Bulk Insert (Gộp Request)
* **Giải pháp**: Gộp toàn bộ dữ liệu Goals và Records thành danh sách và gửi lên Supabase trong 2 request bulk insert duy nhất:
  ```dart
  // Ví dụ bulk insert
  await _client.from('goals').insert(listOfGoalJsons);
  await _client.from('monthly_records').insert(listOfRecordJsons);
  ```
* **Lợi ích**: Giảm số lượng kết nối mạng từ $N$ xuống còn $2$, tăng tốc độ đồng bộ lên gấp nhiều lần.

#### 3. Đồng bộ dạng Database Transaction qua Supabase RPC
* **Giải pháp**: Viết một PostgreSQL function (RPC) trên Supabase nhận toàn bộ cục dữ liệu JSON từ client và thực thi chèn dữ liệu trong một Transaction duy nhất ở phía Server:
  ```sql
  CREATE OR REPLACE FUNCTION sync_user_data(
    p_profile json, 
    p_goals json[], 
    p_records json[]
  ) RETURNS void AS $$
  BEGIN
    -- Thực hiện chèn profile, goals, records trong khối TRANSACTION
    -- Nếu một bảng lỗi, toàn bộ dữ liệu sẽ tự động rollback
  END;
  $$ LANGUAGE plpgsql;
  ```
* **Lợi ích**: Đảm bảo tính nguyên tử (Atomicity). Tránh tuyệt đối việc đồng bộ lỗi một nửa và trùng lặp dữ liệu.

---

### Giai đoạn 2: Nâng cấp Cơ sở dữ liệu Cục bộ (Local Database Engine)

* **Giải pháp**: Thay thế hoàn toàn SharedPreferences đối với các bảng Goals, Records, Scenarios bằng **`Isar Database`** hoặc **`Drift (SQLite)`**.
* **Đặc điểm**:
  * Hỗ trợ ràng buộc khóa ngoại (Foreign Keys) tự động.
  * Hỗ trợ truy vấn SQL/NoSQL tốc độ cao, index tìm kiếm nhanh.
  * Hỗ trợ cơ chế tự động khôi phục dữ liệu khi file lỗi (Crash safety).
  * Chỉ giữ SharedPreferences cho các key cấu hình nhỏ như cài đặt sáng/tối hoặc trạng thái onboarding.

---

### Giai đoạn 3: Chiến lược Giải quyết Xung đột (Conflict Resolution)

Khi người dùng Guest đăng nhập vào tài khoản Google đã có sẵn dữ liệu trên Cloud, hệ thống cần xử lý xung đột theo các bước:

1. **Kiểm tra sự tồn tại của dữ liệu đám mây (Cloud Data Check)**:
   Trước khi đẩy dữ liệu local lên, gửi một request nhanh truy vấn xem tài khoản đó đã có bản ghi nào trên bảng `goals` chưa.
2. **Hiển thị hộp thoại quyết định (User Prompt)**:
   Nếu có dữ liệu online trùng lặp, cung cấp cho người dùng 3 tùy chọn:
   * **Tùy chọn A (Gộp dữ liệu - Merge)**: Giữ cả hai dữ liệu và gộp chung lại (những mục tiêu trùng tên sẽ được giữ lại bản ghi mới nhất theo timestamp `updated_at`).
   * **Tùy chọn B (Giữ dữ liệu trên máy - Use Local)**: Ghi đè toàn bộ dữ liệu online bằng dữ liệu local hiện tại.
   * **Tùy chọn C (Tải dữ liệu từ đám mây - Use Cloud)**: Xóa bỏ dữ liệu Guest hiện tại và đồng bộ tải dữ liệu online cũ về thiết bị.
