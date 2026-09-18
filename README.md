# Bookstore App

Bookstore App is a mobile-first online bookstore built with Flutter, Node.js/Express, and PostgreSQL. The app covers the main shopping flow from browsing books, managing a cart, applying vouchers, choosing shipping, and placing orders. The backend is organized around controller, service, and repository layers, with notable implementation work in authentication, order transactions, payment integration, notifications, and AI-assisted customer support.

## Project Snapshot

| Area | Implementation |
| --- | --- |
| Product | Mobile bookstore app for browsing books, cart checkout, vouchers, shipping, payments, reviews, notifications, and support. |
| Backend | Node.js/Express REST API organized into routes, controllers, services, and repositories. |
| Mobile | Flutter app that calls the REST API, stores session/base URL locally, and handles checkout UI. |
| Database | PostgreSQL schema for users, OTP records, books, inventory, cart, vouchers, payments, orders, reviews, support, notifications, and flash sales. |
| Authentication | bcrypt password hashing, JWT sessions, email OTP verification, password reset, and optional 2FA login. |
| Payments | COD, MoMo payment URL/deeplink, and VietQR QR image generation with persisted `PaymentTransaction` records. |
| Payment security | MoMo requests and callbacks use HMAC-SHA256 signatures. VietQR webhook handling updates by transaction reference/status and does not currently verify a signature or token. |
| AI support | OpenAI Chat Completions can recommend real books and vouchers after validating model output against database records. |

## Tổng Quan Dự Án

| Hạng mục | Triển khai |
| --- | --- |
| Sản phẩm | Ứng dụng bán sách trên mobile, có duyệt sách, giỏ hàng, voucher, vận chuyển, thanh toán, đánh giá, thông báo và hỗ trợ khách hàng. |
| Backend | REST API bằng Node.js/Express, tách lớp theo routes, controllers, services và repositories. |
| Mobile | Ứng dụng Flutter gọi REST API, lưu session/base URL cục bộ và xử lý giao diện checkout. |
| Cơ sở dữ liệu | PostgreSQL với schema cho user, OTP, sách, tồn kho, giỏ hàng, voucher, thanh toán, đơn hàng, review, support, notification và flash sale. |
| Xác thực | Hash mật khẩu bằng bcrypt, JWT session, email OTP, reset mật khẩu và tùy chọn đăng nhập 2FA. |
| Thanh toán | Hỗ trợ COD, MoMo payment URL/deeplink và sinh mã VietQR; mỗi lần thanh toán được lưu trong `PaymentTransaction`. |
| Bảo mật thanh toán | MoMo request và callback được ký/kiểm tra bằng HMAC-SHA256. VietQR webhook hiện cập nhật theo transaction reference/status và chưa có signature/token verification. |
| Hỗ trợ AI | OpenAI Chat Completions gợi ý sách/voucher thật trong database, sau đó backend validate ID/code trước khi trả về app. |

## Key Features

- Browse books by category, search, view details, and manage favorites.
- Register and log in with email/password, Google/Facebook provider IDs, OTP email verification, password reset, and optional two-factor login.
- Manage cart items, delivery addresses, shipping methods, vouchers, and checkout.
- Pay with COD, MoMo redirect/deeplink, or VietQR QR code.
- Track orders, update delivery address/status, review purchased books, and receive order notifications.
- Use an AI chat assistant that can answer bookstore-related questions and suggest real books or vouchers from the database.
- Submit support requests and messages linked to orders.

## Technical Highlights

### Layered Express Backend

The backend follows a clear `routes -> controllers -> services -> repositories` structure. Controllers handle HTTP input/output, services hold business logic, and repositories isolate PostgreSQL queries. This keeps payment, order, auth, voucher, notification, and support logic easier to inspect and change independently.

### Authentication And OTP Flows

Authentication uses bcrypt password hashing and JWT session tokens. Email OTP records are stored with expiry time, verification status, and attempt counts for registration, password reset, account deletion, and two-factor login flows. Some account-sensitive routes are protected by JWT middleware.

### Transactional Order Creation

Order creation is wrapped in a PostgreSQL transaction. A successful order inserts the order and order items, updates inventory quantities, increments voucher usage, removes checked-out cart items, and returns order items for notification creation. If one step fails, the transaction is rolled back.

### Payment Flow

Payment attempts are persisted in `PaymentTransaction` with provider, amount, status, transaction reference, payment URL or QR content, order payload, and raw provider payload. This lets the backend create the order only after a successful online payment callback, while COD can create the order immediately.

- **MoMo initiation:** the backend creates a MoMo payment request, signs the request payload with HMAC-SHA256 using `MOMO_SECRET_KEY`, and stores the returned payment URL/provider transaction ID.
- **MoMo callback/IPN:** MoMo callbacks are verified using HMAC-SHA256 signatures before a transaction is marked as succeeded or failed.
- **VietQR:** the backend generates a VietQR image URL through `img.vietqr.io` using bank BIN, account number, account name, amount, and `BOOKSTORE {txnRef}` as transfer information.
- **VietQR webhook:** the current handler reads `txnRef`/`orderId`/`reference` and `status`/`state` from the payload, updates the matching transaction, and creates the paid order when the status is successful. The code does not currently verify a VietQR signature or webhook token.

### AI-Assisted Book And Voucher Recommendations

The chat service calls OpenAI Chat Completions when `OPENAI_API_KEY` is configured. For book or voucher-related questions, it loads current books/vouchers from PostgreSQL, asks the model to return JSON, parses the response, and validates suggested book IDs and voucher codes against database records before sending results back to Flutter.

### Notifications

The notification API is protected by JWT middleware and supports listing notifications, marking one or all as read, deleting notifications, and reading unread counts. Order creation creates a notification without blocking checkout if notification creation fails.

## Architecture

```mermaid
flowchart LR
  Flutter[Flutter mobile app] --> API[Express REST API]
  API --> Services[Service layer]
  Services --> Repos[Repository layer]
  Repos --> DB[(PostgreSQL)]
  Services --> MoMo[MoMo gateway]
  Services --> VietQR[VietQR image URL]
  Services --> OpenAI[OpenAI Chat Completions]
  Services --> SMTP[SMTP email]
```

## Tech Stack

**Mobile**

- Flutter / Dart
- Provider
- SharedPreferences
- Google Sign-In and Facebook Auth packages
- URL Launcher, Image Picker, Cached Network Image, Geolocator/Geocoding

**Backend**

- Node.js
- Express
- PostgreSQL with `pg`
- JWT with `jsonwebtoken`
- Password hashing with `bcryptjs`
- Email delivery with `nodemailer`
- Native `https` calls for MoMo and OpenAI integrations

**Database**

- PostgreSQL schema in `backend/schema.sql`
- Tables for users, OTP verification, books, inventory, cart, favorites, vouchers, shipping methods, payment methods, payment transactions, orders, reviews, support requests/messages, notifications, and flash sales

**Third-Party Integrations**

- MoMo payment gateway
- VietQR QR image service
- OpenAI Chat Completions
- SMTP email provider
- Google/Facebook sign-in on the Flutter side

## Getting Started

### Prerequisites

- Node.js and npm
- PostgreSQL
- Flutter SDK
- Android Studio, Xcode, or another Flutter-supported device/emulator

### Backend Environment Variables

Create `backend/.env` with values for the services you want to run:

```env
PORT=8080
DATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/DATABASE
JWT_SECRET=replace_with_a_strong_secret

SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your_email@example.com
SMTP_PASS=your_app_password
SMTP_SECURE=false
SMTP_FROM=your_email@example.com

OPENAI_API_KEY=sk-...

MOMO_PARTNER_CODE=your_momo_partner_code
MOMO_ACCESS_KEY=your_momo_access_key
MOMO_SECRET_KEY=your_momo_secret_key
MOMO_ENDPOINT=https://test-payment.momo.vn/v2/gateway/api/create
MOMO_RETURN_URL=http://localhost:8080/payment-return
MOMO_NOTIFY_URL=https://your-public-domain.example.com/api/payments/webhook/momo
MOMO_REQUEST_TYPE=captureWallet
MOMO_LANG=vi

VIETQR_BANK_BIN=your_bank_bin
VIETQR_ACCOUNT_NUMBER=your_account_number
VIETQR_ACCOUNT_NAME=your_account_name
```

`DATABASE_URL` is required at backend startup. MoMo, VietQR, SMTP, and OpenAI features require their related variables only when those flows are used.

### Database Setup

Create a PostgreSQL database, then apply the schema:

```bash
cd backend
psql "$DATABASE_URL" -f schema.sql
```

On Windows PowerShell, use:

```powershell
cd backend
psql $env:DATABASE_URL -f schema.sql
```

### Run Backend

```bash
cd backend
npm install
npm run dev
```

The backend listens on `PORT` or `8080` by default.

### Run Flutter App

```bash
cd bookstore_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

For an Android emulator or a physical device, pass the backend URL reachable from that device:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_MACHINE_IP:8080
```

The app also stores the API base URL in `SharedPreferences`, so a previously saved URL can override the default.

## Project Structure

```text
backend/
  schema.sql
  src/
    app.js
    index.js
    config/
    controllers/
    middleware/
    models/
    repositories/
    routes/
    services/

bookstore_app/
  lib/
    main.dart
    models/
    screens/
    utils/
    widgets/
  assets/
  android/
  ios/
  web/
```

## Main Workflows

### Checkout And Payment

1. Flutter builds an `orderPayload` from cart items, shipping address, shipping method, vouchers, and totals.
2. Flutter calls `POST /api/payments/initiate`.
3. Backend creates a pending `PaymentTransaction`.
4. For COD, the backend marks the transaction succeeded and creates the order immediately.
5. For MoMo, the backend signs and sends a create-payment request, then returns the payment URL/deeplink to Flutter.
6. For VietQR, the backend returns a QR image URL containing the amount and transaction reference.
7. MoMo IPN verifies the callback signature before updating the transaction. VietQR webhook updates by transaction reference and status based on the received payload.
8. When a transaction succeeds, the backend creates the order from the stored payload and links it back to the payment transaction.

### AI Chat Assistant

1. Flutter sends chat messages to `POST /api/chat`.
2. Backend detects whether the question is about books or vouchers.
3. Relevant books/vouchers are loaded from PostgreSQL and injected into the model prompt.
4. The model is asked to return JSON containing a message, book IDs, and voucher codes.
5. Backend parses and validates suggestions against database records before returning them.

## Future Improvements

- Add authentication for VietQR webhook handling, such as a provider signature, shared token, or IP allowlist.
- Apply JWT authorization more consistently across user-owned resources such as cart, orders, favorites, and payments.
- Add automated backend and Flutter tests around payment callbacks, order transaction rollback, OTP limits, and voucher calculations.
- Add screenshots or a short demo video to make the mobile UI easier to evaluate from GitHub.
- Remove committed dependency folders such as `backend/node_modules` from version control if this repository is intended for public review.
