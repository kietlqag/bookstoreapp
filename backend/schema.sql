CREATE TABLE IF NOT EXISTS "User" (
  id SERIAL PRIMARY KEY,
  "fullName" TEXT NOT NULL,
  email TEXT UNIQUE,
  "passwordHash" TEXT,
  "googleId" TEXT UNIQUE,
  "facebookId" TEXT UNIQUE,
  "phoneNumber" TEXT,
  address TEXT,
  avatar TEXT,
  role TEXT NOT NULL DEFAULT 'customer'
);

CREATE TABLE IF NOT EXISTS "UserAddress" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  "fullName" TEXT NOT NULL,
  "phoneNumber" TEXT NOT NULL,
  "addressLine" TEXT NOT NULL,
  "addressLineNew" TEXT,
  "isDefault" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_user_address_user
    FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "uq_user_address_default"
  ON "UserAddress" ("userId")
  WHERE "isDefault" = true;

CREATE TABLE IF NOT EXISTS "OtpVerification" (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  "fullName" TEXT NOT NULL,
  "passwordHash" TEXT NOT NULL,
  code TEXT NOT NULL,
  "expiresAt" TIMESTAMP NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  "verifiedAt" TIMESTAMP,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "Book" (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT,
  price DOUBLE PRECISION,
  discount DOUBLE PRECISION,
  "imageUrl" TEXT,
  description TEXT,
  pages INTEGER,
  language TEXT,
  publisher TEXT,
  year INTEGER,
  "categoryName" TEXT
);

CREATE TABLE IF NOT EXISTS "CartItem" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  "bookId" INTEGER NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_cart_user
    FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_book
    FOREIGN KEY ("bookId") REFERENCES "Book"(id) ON DELETE CASCADE,
  CONSTRAINT uq_cart_user_book UNIQUE ("userId", "bookId")
);

CREATE TABLE IF NOT EXISTS "Favorite" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  "bookId" INTEGER NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_favorite_user
    FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE CASCADE,
  CONSTRAINT fk_favorite_book
    FOREIGN KEY ("bookId") REFERENCES "Book"(id) ON DELETE CASCADE,
  CONSTRAINT uq_favorite_user_book UNIQUE ("userId", "bookId")
);

CREATE TABLE IF NOT EXISTS "Category" (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT UNIQUE,
  description TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS "Review" (
  id SERIAL PRIMARY KEY,
  "bookId" INTEGER NOT NULL,
  "userName" TEXT,
  rating NUMERIC(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
  comment TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_review_book
    FOREIGN KEY ("bookId") REFERENCES "Book"(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Inventory" (
  id SERIAL PRIMARY KEY,
  "bookId" INTEGER NOT NULL UNIQUE,
  "totalQuantity" INTEGER NOT NULL DEFAULT 0,
  "remainingQuantity" INTEGER NOT NULL DEFAULT 0,
  "soldQuantity" INTEGER NOT NULL DEFAULT 0,
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_inventory_book
    FOREIGN KEY ("bookId") REFERENCES "Book"(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Voucher" (
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  "discountType" TEXT NOT NULL,
  "discountValue" NUMERIC(10,2) NOT NULL,
  "maxDiscount" NUMERIC(10,2),
  "minOrderValue" NUMERIC(10,2) NOT NULL DEFAULT 0,
  "startAt" TIMESTAMP,
  "endAt" TIMESTAMP,
  "usageLimit" INTEGER,
  "usedCount" INTEGER NOT NULL DEFAULT 0,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "ShippingMethod" (
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  fee NUMERIC(10,2) NOT NULL,
  "minDays" INTEGER NOT NULL DEFAULT 0,
  "maxDays" INTEGER NOT NULL DEFAULT 0,
  "sortOrder" INTEGER NOT NULL DEFAULT 0,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "PaymentMethod" (
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  provider TEXT NOT NULL,
  "methodType" TEXT NOT NULL,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "sortOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "PaymentTransaction" (
  id SERIAL PRIMARY KEY,
  "orderId" INTEGER,
  "methodCode" TEXT NOT NULL,
  provider TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'VND',
  status TEXT NOT NULL DEFAULT 'pending',
  "txnRef" TEXT,
  "providerTxnId" TEXT,
  "paymentUrl" TEXT,
  "qrContent" TEXT,
  "orderPayload" JSONB,
  "rawPayload" JSONB,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "UserContactOtp" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  code TEXT NOT NULL,
  "expiresAt" TIMESTAMP NOT NULL,
  "verifiedAt" TIMESTAMP,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_payment_transaction_ref"
  ON "PaymentTransaction" ("txnRef");

CREATE INDEX IF NOT EXISTS "idx_payment_transaction_provider"
  ON "PaymentTransaction" (provider, status);

INSERT INTO "PaymentMethod" (code, title, provider, "methodType", "sortOrder")
VALUES
  ('MOMO', 'MoMo', 'momo', 'redirect', 2),
  ('VIETQR', 'VietQR', 'vietqr', 'qr', 3),
  ('COD', 'Thanh toán khi nhận hàng', 'cod', 'offline', 0)
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS "Order" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  "serviceId" INTEGER,
  "paymentId" INTEGER,
  "shippingAddressNew" TEXT,
  "shippingAddressOld" TEXT,
  "phoneNumber" TEXT,
  note TEXT,
  "totalPrice" NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending_confirmation',
  "orderDate" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "OrderItem" (
  id SERIAL PRIMARY KEY,
  "orderId" INTEGER NOT NULL,
  "bookId" INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price NUMERIC(12,2) NOT NULL
);

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending_confirmation';

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "orderDate" TIMESTAMP NOT NULL DEFAULT NOW();

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "shippingAddressNew" TEXT;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "shippingAddressOld" TEXT;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS subtotal NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "shippingFee" NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "productDiscount" NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "shippingDiscount" NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Order"
  ADD COLUMN IF NOT EXISTS "recipientName" TEXT;

ALTER TABLE IF EXISTS "PaymentTransaction"
  ADD COLUMN IF NOT EXISTS "orderPayload" JSONB;

ALTER TABLE IF EXISTS "User"
  ADD COLUMN IF NOT EXISTS avatar TEXT;

ALTER TABLE IF EXISTS "UserContactOtp"
  ADD COLUMN IF NOT EXISTS "verifiedAt" TIMESTAMP;
