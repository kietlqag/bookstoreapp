-- Tạo bảng Notification
CREATE TABLE IF NOT EXISTS "Notification" (
  id SERIAL PRIMARY KEY,
  "userId" INTEGER NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'order', 'promotion', 'product', 'system'
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  "isRead" BOOLEAN NOT NULL DEFAULT false,
  "relatedId" INTEGER, -- ID liên quan (orderId, voucherId, bookId, etc.)
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Thêm foreign key constraint
ALTER TABLE "Notification"
ADD CONSTRAINT fk_notification_user
  FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE CASCADE;

-- Thêm indexes
CREATE INDEX IF NOT EXISTS "idx_notification_user"
  ON "Notification" ("userId");

CREATE INDEX IF NOT EXISTS "idx_notification_user_read"
  ON "Notification" ("userId", "isRead");

CREATE INDEX IF NOT EXISTS "idx_notification_created"
  ON "Notification" ("createdAt" DESC);
