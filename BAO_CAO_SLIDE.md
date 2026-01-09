# BÁO CÁO DỰ ÁN BOOKSTORE APP

## SLIDE 1: TRANG BÌA
**ỨNG DỤNG MUA SÁCH TRỰC TUYẾN**
- Tên dự án: Bookstore App (KBook)
- Người thực hiện: [Tên của bạn]
- Ngày báo cáo: [Ngày hiện tại]

---

## SLIDE 2: GIỚI THIỆU DỰ ÁN
### Mục tiêu
- Xây dựng ứng dụng mua sách trực tuyến đa nền tảng
- Cung cấp trải nghiệm mua sắm thuận tiện và hiện đại
- Quản lý kho sách, đơn hàng và khách hàng hiệu quả

### Đối tượng sử dụng
- Khách hàng: Mua sách, xem đánh giá, quản lý đơn hàng
- Quản trị viên: Quản lý sản phẩm, đơn hàng, người dùng

---

## SLIDE 3: KIẾN TRÚC HỆ THỐNG
### Công nghệ sử dụng

**Frontend (Mobile App)**
- Framework: Flutter (Dart)
- Platform: Android, iOS, Windows
- UI/UX: Material Design
- State Management: StatefulWidget

**Backend (API Server)**
- Runtime: Node.js
- Framework: Express.js
- Database: PostgreSQL
- Authentication: JWT (JSON Web Token)
- Real-time: Socket.io

**Công nghệ bổ sung**
- Email: Nodemailer (OTP, thông báo)
- Social Login: Google Sign-In, Facebook Auth
- Location: Geolocator, Geocoding
- Image: Image Picker, Cached Network Image

---

## SLIDE 4: TÍNH NĂNG CHÍNH - PHẦN 1

### 1. Xác thực người dùng (Authentication)
- ✅ Đăng ký/Đăng nhập với email và mật khẩu
- ✅ Xác thực 2 bước (2FA) qua OTP email
- ✅ Đăng nhập xã hội (Google, Facebook)
- ✅ Quên mật khẩu và đặt lại mật khẩu
- ✅ Bảo mật với JWT token

### 2. Quản lý sách (Book Management)
- ✅ Danh sách sách theo danh mục
- ✅ Tìm kiếm sách
- ✅ Chi tiết sách (mô tả, giá, đánh giá)
- ✅ Sách nổi bật, sách bán chạy
- ✅ Flash sale (khuyến mãi giờ vàng)

---

## SLIDE 5: TÍNH NĂNG CHÍNH - PHẦN 2

### 3. Giỏ hàng và Thanh toán
- ✅ Thêm/Xóa sản phẩm vào giỏ hàng
- ✅ Cập nhật số lượng
- ✅ Áp dụng voucher/khuyến mãi
- ✅ Chọn phương thức vận chuyển
- ✅ Chọn phương thức thanh toán
- ✅ Xác nhận đơn hàng

### 4. Quản lý đơn hàng
- ✅ Xem lịch sử đơn hàng
- ✅ Chi tiết đơn hàng
- ✅ Theo dõi trạng thái đơn hàng
- ✅ Đánh giá sản phẩm sau khi mua

---

## SLIDE 6: TÍNH NĂNG CHÍNH - PHẦN 3

### 5. Quản lý người dùng
- ✅ Hồ sơ cá nhân
- ✅ Chỉnh sửa thông tin
- ✅ Quản lý địa chỉ giao hàng
- ✅ Danh sách yêu thích
- ✅ Cài đặt thông báo, quyền riêng tư

### 6. Hỗ trợ khách hàng
- ✅ Chat hỗ trợ trực tuyến (Socket.io)
- ✅ Gửi yêu cầu hỗ trợ
- ✅ Xem lịch sử hỗ trợ
- ✅ Thông báo đẩy (Notifications)

---

## SLIDE 7: CƠ SỞ DỮ LIỆU
### Các bảng chính

**Quản lý người dùng**
- users (thông tin người dùng)
- addresses (địa chỉ giao hàng)

**Quản lý sản phẩm**
- books (sách)
- categories (danh mục)
- reviews (đánh giá)
- favorites (yêu thích)

**Quản lý đơn hàng**
- orders (đơn hàng)
- order_items (chi tiết đơn hàng)
- cart_items (giỏ hàng)

**Hệ thống**
- vouchers (mã giảm giá)
- shipping_methods (phương thức vận chuyển)
- payment_methods (phương thức thanh toán)
- support_requests (yêu cầu hỗ trợ)
- notifications (thông báo)
- flash_sales (khuyến mãi)

---

## SLIDE 8: API ENDPOINTS
### Các nhóm API chính

**Authentication** (`/api/auth`)
- POST `/register` - Đăng ký
- POST `/login` - Đăng nhập
- POST `/verify` - Xác thực OTP
- POST `/forgot-password` - Quên mật khẩu
- POST `/social/login` - Đăng nhập xã hội

**Books** (`/api/books`)
- GET `/` - Danh sách sách
- GET `/:id` - Chi tiết sách
- GET `/search` - Tìm kiếm

**Orders** (`/api/orders`)
- GET `/` - Lịch sử đơn hàng
- POST `/` - Tạo đơn hàng
- GET `/:id` - Chi tiết đơn hàng

**Cart** (`/api/cart`)
- GET `/:userId` - Lấy giỏ hàng
- POST `/` - Thêm vào giỏ
- PUT `/:id` - Cập nhật
- DELETE `/:id` - Xóa

**Support** (`/api/support`)
- POST `/requests` - Gửi yêu cầu
- GET `/requests/:userId` - Lịch sử
- POST `/messages` - Gửi tin nhắn

---

## SLIDE 9: GIAO DIỆN NGƯỜI DÙNG
### Các màn hình chính

**Màn hình xác thực**
- Welcome Screen (Giới thiệu app)
- Login Page (Đăng nhập)
- Register Page (Đăng ký)
- Forgot Password (Quên mật khẩu)

**Màn hình chính**
- Home Page (Trang chủ với danh mục, sách nổi bật)
- Book Detail (Chi tiết sách)
- Search Page (Tìm kiếm)
- Category Books (Sách theo danh mục)

**Màn hình mua sắm**
- Cart Page (Giỏ hàng)
- Checkout Page (Thanh toán)
- Order List (Lịch sử đơn hàng)
- Order Detail (Chi tiết đơn hàng)

**Màn hình cá nhân**
- Profile Page (Hồ sơ)
- Favorites Page (Yêu thích)
- Settings (Cài đặt)
- Support (Hỗ trợ)

---

## SLIDE 10: BẢO MẬT
### Các biện pháp bảo mật

**Xác thực và Phân quyền**
- JWT Token cho session management
- Bcrypt để hash mật khẩu
- 2FA (Two-Factor Authentication) qua email OTP
- Middleware xác thực cho protected routes

**Bảo mật API**
- CORS configuration
- Input validation
- SQL injection prevention (parameterized queries)
- Error handling không lộ thông tin nhạy cảm

**Bảo mật Mobile**
- Network Security Config (Android)
- Secure storage cho tokens
- HTTPS/HTTP cleartext configuration

---

## SLIDE 11: TÍNH NĂNG NỔI BẬT
### Điểm mạnh của ứng dụng

**1. Trải nghiệm người dùng**
- UI/UX hiện đại, dễ sử dụng
- Tải ảnh nhanh với cached images
- Responsive design cho nhiều kích thước màn hình

**2. Hiệu năng**
- Lazy loading cho danh sách sách
- Caching dữ liệu local
- Optimized API calls

**3. Tính năng đặc biệt**
- Flash sale với countdown timer
- Real-time chat support
- Push notifications
- Social login tích hợp
- Đánh giá và review sách

---

## SLIDE 12: THỬ NGHIỆM VÀ KIỂM THỬ
### Các test case đã thực hiện

**Chức năng đăng nhập/đăng ký**
- ✅ Đăng ký thành công
- ✅ Đăng nhập với email/password
- ✅ Xác thực OTP
- ✅ Đăng nhập xã hội (Google, Facebook)
- ✅ Quên mật khẩu

**Chức năng mua sắm**
- ✅ Thêm sách vào giỏ hàng
- ✅ Cập nhật số lượng
- ✅ Áp dụng voucher
- ✅ Tạo đơn hàng
- ✅ Xem lịch sử đơn hàng

**Chức năng khác**
- ✅ Tìm kiếm sách
- ✅ Xem chi tiết sách
- ✅ Thêm vào yêu thích
- ✅ Chat hỗ trợ
- ✅ Cập nhật profile

---

## SLIDE 13: KẾT QUẢ ĐẠT ĐƯỢC
### Thống kê dự án

**Số lượng tính năng**
- 6 module chính
- 30+ màn hình
- 50+ API endpoints
- 15+ database tables

**Công nghệ áp dụng**
- Frontend: Flutter (cross-platform)
- Backend: Node.js + Express
- Database: PostgreSQL
- Real-time: Socket.io

**Tính năng hoàn thành**
- ✅ Authentication & Authorization
- ✅ Book Management
- ✅ Shopping Cart & Checkout
- ✅ Order Management
- ✅ User Profile
- ✅ Support System
- ✅ Notifications
- ✅ Reviews & Ratings

---

## SLIDE 14: KHÓ KHĂN VÀ GIẢI PHÁP
### Vấn đề gặp phải

**1. Kết nối giữa Mobile và Backend**
- **Vấn đề**: LDPlayer emulator không dùng IP 10.0.2.2 như Android emulator chuẩn
- **Giải pháp**: Cấu hình IP WiFi thật (10.90.222.178) cho Android

**2. Navigation Error**
- **Vấn đề**: Lỗi `_history.isNotEmpty` khi đăng nhập
- **Giải pháp**: Loại bỏ `pushAndRemoveUntil`, dùng state-based navigation

**3. Network Security**
- **Vấn đề**: Android chặn HTTP traffic
- **Giải pháp**: Cấu hình Network Security Config cho phép cleartext traffic

**4. CORS và API**
- **Vấn đề**: CORS blocking requests
- **Giải pháp**: Cấu hình CORS middleware đúng cách

---

## SLIDE 15: HƯỚNG PHÁT TRIỂN
### Kế hoạch tương lai

**Ngắn hạn (1-3 tháng)**
- Tối ưu hiệu năng và tốc độ tải
- Thêm unit tests và integration tests
- Cải thiện UI/UX dựa trên feedback
- Thêm tính năng thanh toán online (VNPay, MoMo)

**Trung hạn (3-6 tháng)**
- Phát triển admin dashboard
- Thêm tính năng recommend sách (AI/ML)
- Tích hợp hệ thống inventory management
- Push notifications cho đơn hàng

**Dài hạn (6-12 tháng)**
- Mở rộng sang web platform
- Tích hợp nhiều nhà cung cấp sách
- Hệ thống affiliate marketing
- Mobile app cho iOS và Android native

---

## SLIDE 16: KẾT LUẬN
### Tóm tắt

**Thành công đạt được**
- ✅ Xây dựng thành công ứng dụng bookstore đầy đủ tính năng
- ✅ Kiến trúc rõ ràng, dễ bảo trì và mở rộng
- ✅ Áp dụng các best practices trong phát triển
- ✅ Trải nghiệm người dùng tốt với UI/UX hiện đại

**Bài học kinh nghiệm**
- Hiểu rõ về cross-platform development với Flutter
- Kinh nghiệm xử lý authentication và security
- Kỹ năng thiết kế API RESTful
- Xử lý real-time communication với Socket.io

**Cảm ơn!**
- Q&A

---

## PHỤ LỤC: DEMO
### Các tính năng demo

1. **Đăng ký/Đăng nhập**
   - Đăng ký tài khoản mới
   - Xác thực OTP qua email
   - Đăng nhập và quản lý session

2. **Mua sắm**
   - Duyệt sách theo danh mục
   - Tìm kiếm sách
   - Xem chi tiết sách
   - Thêm vào giỏ hàng

3. **Thanh toán**
   - Xem giỏ hàng
   - Áp dụng voucher
   - Chọn địa chỉ và phương thức vận chuyển
   - Tạo đơn hàng

4. **Quản lý**
   - Xem lịch sử đơn hàng
   - Cập nhật profile
   - Quản lý địa chỉ
   - Chat hỗ trợ

---

## GHI CHÚ CHO THUYẾT TRÌNH

### Slide 1-2: Giới thiệu (2 phút)
- Giới thiệu dự án và mục tiêu
- Đặt vấn đề và giải pháp

### Slide 3-6: Kiến trúc và Tính năng (5 phút)
- Trình bày công nghệ sử dụng
- Giới thiệu các tính năng chính
- Có thể demo một số tính năng

### Slide 7-9: Kỹ thuật (3 phút)
- Database schema
- API design
- UI/UX screenshots

### Slide 10-12: Bảo mật và Testing (3 phút)
- Các biện pháp bảo mật
- Quá trình testing
- Kết quả đạt được

### Slide 13-15: Kết quả và Tương lai (3 phút)
- Tổng kết thành quả
- Khó khăn và giải pháp
- Hướng phát triển

### Slide 16: Kết luận (1 phút)
- Tóm tắt
- Q&A

**Tổng thời gian: ~17 phút + Q&A**
