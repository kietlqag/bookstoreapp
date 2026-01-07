const https = require('https');
const bookService = require('./book.service');
const voucherService = require('./voucher.service');

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_API_URL = 'api.openai.com';

const SYSTEM_PROMPT = `Bạn là trợ lý AI thông minh của một cửa hàng sách trực tuyến. 
Nhiệm vụ của bạn là hỗ trợ khách hàng với các vấn đề liên quan đến:
- Sản phẩm sách (tìm kiếm, giới thiệu, thông tin chi tiết)
- Voucher và khuyến mãi (mã giảm giá, ưu đãi, điều kiện sử dụng)
- Đơn hàng (theo dõi, tra cứu, trạng thái)
- Vận chuyển và giao hàng
- Thanh toán
- Chính sách đổi trả
- Hỗ trợ kỹ thuật cơ bản

Khi khách hàng hỏi về sách, bạn sẽ nhận được danh sách sách từ database. 
Hãy phân tích yêu cầu của khách hàng và chọn ra các sách phù hợp nhất để đề xuất.
Trả lời bằng tiếng Việt, ngắn gọn và dễ hiểu.

QUAN TRỌNG - FORMAT PHẢN HỒI:
Bạn PHẢI LUÔN trả lời BẰNG JSON ĐÚNG CÚ PHÁP, không có text thêm, không có markdown, chỉ JSON thuần:

{
  "message": "Câu trả lời tự nhiên, thân thiện cho khách hàng",
  "bookIds": [1, 2, 3],
  "voucherCodes": ["CODE1", "CODE2"]
}

Trong đó:
- "message": (BẮT BUỘC) Câu trả lời tự nhiên, ngắn gọn (2-3 câu), giới thiệu sách/voucher bạn sẽ đề xuất
- "bookIds": (BẮT BUỘC) Mảng số nguyên ID của các sách bạn muốn đề xuất từ danh sách được cung cấp (tối đa 5 sách, chọn sách PHÙ HỢP NHẤT với yêu cầu). Phải là mảng rỗng [] nếu không có sách.
- "voucherCodes": (BẮT BUỘC) Mảng chuỗi mã voucher bạn muốn đề xuất từ danh sách được cung cấp (tối đa 5 voucher). Phải là mảng rỗng [] nếu không có voucher.

KHÔNG được thêm bất kỳ text nào ngoài JSON. Không dùng markdown code blocks.

Ví dụ khi user nói "Tôi muốn mua sách văn học":
{
  "message": "Tuyệt vời! Tôi đã tìm thấy một số sách văn học phù hợp với bạn. Dưới đây là các gợi ý:",
  "bookIds": [5, 12, 18],
  "voucherCodes": []
}

Ví dụ khi user nói "Có voucher nào không":
{
  "message": "Hiện tại cửa hàng có các mã giảm giá sau. Bạn có thể sử dụng khi thanh toán:",
  "bookIds": [],
  "voucherCodes": ["SUMMER2024", "WELCOME10"]
}

Nếu không có sách hoặc voucher để đề xuất:
{
  "message": "Câu trả lời của bạn",
  "bookIds": [],
  "voucherCodes": []
}`;

// Kiểm tra xem message có liên quan đến sách không
function isBookRelated(message) {
  const lowerMessage = message.toLowerCase();
  const bookIndicators = ['sách', 'book', 'cuốn', 'quyển', 'tác giả', 'tác phẩm'];
  return bookIndicators.some(indicator => lowerMessage.includes(indicator));
}

// Kiểm tra xem message có liên quan đến voucher không
function isVoucherRelated(message) {
  const lowerMessage = message.toLowerCase();
  const voucherIndicators = ['voucher', 'mã giảm giá', 'khuyến mãi', 'giảm giá', 'coupon', 'promo', 'ưu đãi'];
  return voucherIndicators.some(indicator => lowerMessage.includes(indicator));
}

async function chatWithAI(messages) {
  if (!OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY is not configured.');
  }

  const lastMessage = messages[messages.length - 1];
  const userMessage = lastMessage?.content || '';
  
  // Lấy danh sách sách và voucher nếu cần
  let allBooks = [];
  let allVouchers = [];
  let isBookQuery = isBookRelated(userMessage);
  let isVoucherQuery = isVoucherRelated(userMessage);
  
  console.log(`[Chat] isBookQuery=${isBookQuery}, isVoucherQuery=${isVoucherQuery}, userMessage="${userMessage}"`);
  
  // Load tất cả sách nếu liên quan đến sách
  if (isBookQuery) {
    try {
      allBooks = await bookService.listBooks();
      console.log(`[Chat] Loaded ${allBooks.length} books for GPT to analyze`);
      if (allBooks.length === 0) {
        console.log(`[Chat] Warning: bookService.listBooks() returned empty array`);
      }
    } catch (error) {
      console.error('[Chat] Error loading books:', error);
      console.error('[Chat] Error stack:', error.stack);
    }
  } else {
    console.log(`[Chat] Query is not book-related, skipping book loading`);
  }
  
  // Load voucher nếu liên quan đến voucher
  if (isVoucherQuery) {
    try {
      allVouchers = await voucherService.listVouchers({ activeOnly: true });
      console.log(`[Chat] Loaded ${allVouchers.length} active vouchers for GPT to analyze`);
    } catch (error) {
      console.error('Error loading vouchers:', error);
    }
  }

  // Thêm system prompt và dữ liệu vào context
  let enhancedSystemPrompt = SYSTEM_PROMPT;
  let hasDataToShow = false;
  
  if (isBookQuery && allBooks.length > 0) {
    const booksInfo = allBooks.map((book, index) => {
      // Lấy 100 ký tự đầu của description (nếu có) để GPT hiểu nội dung sách
      const descriptionPreview = book.description 
        ? (book.description.length > 100 ? book.description.substring(0, 100) + '...' : book.description)
        : 'Không có mô tả';
      
      return `${index + 1}. ID: ${book.id}
   - Tiêu đề: "${book.title}"
   - Tác giả: ${book.author}
   - Danh mục: ${book.categoryName || 'Chưa phân loại'}
   - Mô tả: ${descriptionPreview}
   - Giá: ${book.price}đ`;
    }).join('\n\n');
    
    enhancedSystemPrompt += `\n\nDanh sách sách hiện có trong cửa hàng (${allBooks.length} sách):\n\n${booksInfo}\n\nKhi khách hàng hỏi về sách, hãy phân tích yêu cầu dựa trên: tiêu đề, tác giả, danh mục, và đặc biệt là MÔ TẢ của sách để chọn ra các sách phù hợp nhất từ danh sách trên.`;
    hasDataToShow = true;
  }
  
  if (isVoucherQuery && allVouchers.length > 0) {
    const vouchersInfo = allVouchers.map((voucher, index) => {
      let discountInfo = '';
      if (voucher.discountType === 'percentage') {
        discountInfo = `Giảm ${voucher.discountValue}%`;
        if (voucher.maxDiscount) {
          discountInfo += ` (tối đa ${voucher.maxDiscount}đ)`;
        }
      } else {
        discountInfo = `Giảm ${voucher.discountValue}đ`;
      }
      
      // Format thời gian hiệu lực
      let validPeriod = '';
      if (voucher.startAt && voucher.endAt) {
        validPeriod = `Từ ${new Date(voucher.startAt).toLocaleDateString('vi-VN')} đến ${new Date(voucher.endAt).toLocaleDateString('vi-VN')}`;
      } else if (voucher.endAt) {
        validPeriod = `Có hiệu lực đến ${new Date(voucher.endAt).toLocaleDateString('vi-VN')}`;
      }
      
      return `${index + 1}. Code: "${voucher.code}"
   - Tiêu đề: ${voucher.title}
   - Ưu đãi: ${discountInfo}
   - Đơn tối thiểu: ${voucher.minOrderValue}đ
   - Mô tả: ${voucher.description || 'Không có mô tả'}
   ${validPeriod ? `- Thời gian: ${validPeriod}` : ''}`;
    }).join('\n\n');
    
    enhancedSystemPrompt += `\n\nDanh sách voucher/khuyến mãi hiện có (${allVouchers.length} voucher):\n\n${vouchersInfo}\n\nKhi khách hàng hỏi về voucher, mã giảm giá, khuyến mãi, hãy phân tích yêu cầu dựa trên: tiêu đề, mức giảm giá, điều kiện đơn tối thiểu, và đặc biệt là MÔ TẢ để đề xuất các voucher phù hợp nhất từ danh sách trên.`;
    hasDataToShow = true;
  }
  
  if (hasDataToShow) {
    enhancedSystemPrompt += `\n\nTrả về JSON với format đã hướng dẫn, bao gồm bookIds và voucherCodes (nếu có).`;
  }

  // Thêm system prompt vào đầu messages
  const fullMessages = [
    { role: 'system', content: enhancedSystemPrompt },
    ...messages,
  ];

  const requestData = JSON.stringify({
    model: 'gpt-3.5-turbo',
    messages: fullMessages,
    temperature: 0.7,
    max_tokens: 500,
    response_format: { type: 'json_object' }, // Buộc GPT trả về JSON
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: OPENAI_API_URL,
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Length': Buffer.byteLength(requestData),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', async () => {
        try {
          const response = JSON.parse(data);
          
          if (res.statusCode !== 200) {
            reject(
              new Error(
                response.error?.message ||
                  `OpenAI API error: ${res.statusCode}`,
              ),
            );
            return;
          }

          let content =
            response.choices?.[0]?.message?.content || 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
          
          // Phân tích response từ GPT để lấy message, bookIds và voucherCodes
          let suggestedBookIds = [];
          let suggestedVoucherCodes = [];
          let message = content;
          
          // Thử parse JSON từ response
          try {
            // Loại bỏ markdown code blocks nếu có
            let jsonContent = content.trim();
            jsonContent = jsonContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
            
            // Thử parse JSON
            const parsed = JSON.parse(jsonContent);
            if (parsed.message) {
              message = parsed.message;
            }
            if (parsed.bookIds && Array.isArray(parsed.bookIds)) {
              suggestedBookIds = parsed.bookIds.slice(0, 5); // Giới hạn 5 sách
            }
            if (parsed.voucherCodes && Array.isArray(parsed.voucherCodes)) {
              suggestedVoucherCodes = parsed.voucherCodes.slice(0, 5); // Giới hạn 5 voucher
            }
            console.log(`[Chat] Parsed JSON: message length=${message.length}, bookIds=${suggestedBookIds.length}, voucherCodes=${suggestedVoucherCodes.length}`);
          } catch (parseError) {
            // Nếu không parse được JSON, thử tìm JSON trong text
            try {
              const jsonMatch = content.match(/\{[\s\S]*\}/);
              if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                if (parsed.message) {
                  message = parsed.message;
                }
                if (parsed.bookIds && Array.isArray(parsed.bookIds)) {
                  suggestedBookIds = parsed.bookIds.slice(0, 5);
                }
                if (parsed.voucherCodes && Array.isArray(parsed.voucherCodes)) {
                  suggestedVoucherCodes = parsed.voucherCodes.slice(0, 5);
                }
                console.log(`[Chat] Parsed JSON from text: message length=${message.length}, bookIds=${suggestedBookIds.length}, voucherCodes=${suggestedVoucherCodes.length}`);
              } else {
                console.log('[Chat] Response is not JSON, using plain message');
              }
            } catch (secondParseError) {
              console.log('[Chat] Failed to parse JSON, using plain message');
            }
          }
          
          // Lấy thông tin sách từ bookIds (chỉ đề xuất khi GPT thực sự đề xuất và tìm thấy)
          let suggestedBooks = [];
          if (suggestedBookIds.length > 0) {
            if (allBooks.length === 0) {
              console.log(`[Chat] Warning: No books loaded but GPT suggested IDs: ${suggestedBookIds.join(', ')}`);
              console.log(`[Chat] Debug: isBookQuery=${isBookQuery}, userMessage="${userMessage}"`);
              // Load sách nếu chưa load (chỉ khi GPT đã đề xuất IDs)
              try {
                console.log(`[Chat] Attempting to load books since GPT suggested IDs...`);
                allBooks = await bookService.listBooks();
                console.log(`[Chat] Loaded ${allBooks.length} books`);
              } catch (fallbackError) {
                console.error('[Chat] Error loading books:', fallbackError);
              }
            }
            
            if (allBooks.length > 0) {
              // Chuyển bookIds sang số nguyên để so sánh đúng
              const bookIdsAsNumbers = suggestedBookIds.map(id => typeof id === 'string' ? parseInt(id, 10) : id);
              console.log(`[Chat] Looking for ${bookIdsAsNumbers.length} books (IDs: ${bookIdsAsNumbers.join(', ')}) in ${allBooks.length} total books`);
              console.log(`[Chat] Available book IDs (first 10): ${allBooks.slice(0, 10).map(b => b.id).join(', ')}`);
              
              suggestedBooks = allBooks.filter(book => 
                bookIdsAsNumbers.includes(book.id)
              );
              console.log(`[Chat] Found ${suggestedBooks.length} books (IDs: ${suggestedBooks.map(b => b.id).join(', ')})`);
              
              if (suggestedBooks.length < bookIdsAsNumbers.length) {
                const foundIds = suggestedBooks.map(b => b.id);
                const missingIds = bookIdsAsNumbers.filter(id => !foundIds.includes(id));
                console.log(`[Chat] Warning: Some book IDs from GPT not found in database: ${missingIds.join(', ')}`);
              }
              
              // KHÔNG có fallback - nếu không tìm thấy thì để suggestedBooks = []
            }
          } else {
            console.log(`[Chat] No book IDs suggested by GPT - no books will be suggested`);
            // KHÔNG đề xuất sách phổ biến nếu GPT không đề xuất
          }
          
          // Lấy thông tin voucher từ voucherCodes
          let suggestedVouchers = [];
          if (suggestedVoucherCodes.length > 0 && allVouchers.length > 0) {
            suggestedVouchers = allVouchers.filter(voucher => 
              suggestedVoucherCodes.includes(voucher.code)
            );
            console.log(`[Chat] GPT selected ${suggestedVouchers.length} vouchers (Codes: ${suggestedVoucherCodes.join(', ')}) from ${allVouchers.length} total vouchers`);
          }
          
          console.log(`[Chat] Final response: message length=${message.length}, books=${suggestedBooks.length}, vouchers=${suggestedVouchers.length}`);
          
          resolve({
            message: message,
            suggestedBooks: suggestedBooks,
            suggestedVouchers: suggestedVouchers,
          });
        } catch (error) {
          reject(new Error('Failed to parse OpenAI response.'));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(requestData);
    req.end();
  });
}

module.exports = { chatWithAI };
