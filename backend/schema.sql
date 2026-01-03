CREATE TABLE IF NOT EXISTS "User" (
  id SERIAL PRIMARY KEY,
  "fullName" TEXT NOT NULL,
  email TEXT UNIQUE,
  "passwordHash" TEXT,
  "googleId" TEXT UNIQUE,
  "facebookId" TEXT UNIQUE,
  "phoneNumber" TEXT,
  address TEXT,
  role TEXT NOT NULL DEFAULT 'customer'
);

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
