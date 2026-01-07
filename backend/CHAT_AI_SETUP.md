# Hướng dẫn cấu hình Chat AI với OpenAI

## Yêu cầu

1. Có tài khoản OpenAI và API key
2. Backend đã được cài đặt và chạy

## Cấu hình

1. Tạo file `.env` trong thư mục `backend/` (nếu chưa có)

2. Thêm dòng sau vào file `.env`:

```
OPENAI_API_KEY=sk-your-openai-api-key-here
```

Thay `sk-your-openai-api-key-here` bằng API key thực tế của bạn.

3. Khởi động lại backend server

## Lưu ý

- API key sẽ được lưu trên server, không được expose ra client
- Chat AI chỉ trả lời các câu hỏi liên quan đến cửa hàng sách
- Nếu không có API key, endpoint `/api/chat` sẽ trả về lỗi

## Test

Sau khi cấu hình, bạn có thể test bằng cách:
1. Mở app Flutter
2. Nhấn vào nút chat nổi ở góc dưới bên phải
3. Bắt đầu trò chuyện với AI
