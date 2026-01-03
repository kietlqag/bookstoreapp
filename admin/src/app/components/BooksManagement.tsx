import { useState } from 'react';
import { Search, Plus, Edit, Trash2, BookOpen } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

const booksData = [
  {
    id: 1,
    title: 'Đắc Nhân Tâm',
    author: 'Dale Carnegie',
    category: 'Kỹ năng sống',
    price: 80000,
    stock: 245,
    sold: 1234,
    publisher: 'First News',
    year: 2021,
  },
  {
    id: 2,
    title: 'Nhà Giả Kim',
    author: 'Paulo Coelho',
    category: 'Văn học',
    price: 80000,
    stock: 189,
    sold: 987,
    publisher: 'NXB Hội Nhà Văn',
    year: 2020,
  },
  {
    id: 3,
    title: 'Sapiens: Lược sử loài người',
    author: 'Yuval Noah Harari',
    category: 'Khoa học',
    price: 100000,
    stock: 156,
    sold: 876,
    publisher: 'NXB Trẻ',
    year: 2022,
  },
  {
    id: 4,
    title: 'Atomic Habits',
    author: 'James Clear',
    category: 'Kỹ năng sống',
    price: 100000,
    stock: 234,
    sold: 765,
    publisher: 'First News',
    year: 2021,
  },
  {
    id: 5,
    title: 'Think and Grow Rich',
    author: 'Napoleon Hill',
    category: 'Kinh tế',
    price: 100000,
    stock: 178,
    sold: 654,
    publisher: 'NXB Tổng hợp TP.HCM',
    year: 2020,
  },
  {
    id: 6,
    title: 'Tôi Tài Giỏi, Bạn Cũng Thế',
    author: 'Adam Khoo',
    category: 'Kỹ năng sống',
    price: 95000,
    stock: 198,
    sold: 543,
    publisher: 'First News',
    year: 2021,
  },
  {
    id: 7,
    title: 'Tuổi Trẻ Đáng Giá Bao Nhiêu',
    author: 'Rosie Nguyễn',
    category: 'Kỹ năng sống',
    price: 85000,
    stock: 267,
    sold: 432,
    publisher: 'Hà Nội',
    year: 2022,
  },
  {
    id: 8,
    title: 'Cà Phê Cùng Tony',
    author: 'Tony Buổi Sáng',
    category: 'Tản văn',
    price: 70000,
    stock: 312,
    sold: 398,
    publisher: 'Công Thương',
    year: 2021,
  },
];

export function BooksManagement() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const categories = ['all', 'Kỹ năng sống', 'Văn học', 'Khoa học', 'Kinh tế', 'Tản văn'];

  const filteredBooks = booksData.filter((book) => {
    const matchesSearch =
      book.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      book.author.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory =
      selectedCategory === 'all' || book.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold text-gray-900">Quản lý sách</h2>
          <p className="text-gray-500 mt-1">Quản lý thông tin sách trong cửa hàng</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Plus className="w-5 h-5" />
          <span>Thêm sách mới</span>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl p-6 border border-gray-200">
        <div className="flex flex-col lg:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo tên sách hoặc tác giả..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="all">Tất cả thể loại</option>
            {categories.slice(1).map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Books Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Sách
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Thể loại
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Giá
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Tồn kho
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Đã bán
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  NXB
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredBooks.map((book) => (
                <tr key={book.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <BookOpen className="w-5 h-5 text-blue-600" />
                      </div>
                      <div>
                        <div className="font-medium text-gray-900">{book.title}</div>
                        <div className="text-sm text-gray-500">{book.author}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 text-xs rounded-full bg-purple-100 text-purple-800">
                      {book.category}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-900">
                    {book.price.toLocaleString()}₫
                  </td>
                  <td className="px-6 py-4">
                    <span className={`font-medium ${book.stock < 100 ? 'text-red-600' : 'text-gray-900'}`}>
                      {book.stock}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-900">{book.sold}</td>
                  <td className="px-6 py-4 text-sm text-gray-500">{book.publisher}</td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                        <Edit className="w-4 h-4 text-gray-600" />
                      </button>
                      <button className="p-2 hover:bg-red-50 rounded-lg transition-colors">
                        <Trash2 className="w-4 h-4 text-red-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-gray-500">
          Hiển thị <span className="font-medium">{filteredBooks.length}</span> trong tổng số{' '}
          <span className="font-medium">{booksData.length}</span> sách
        </p>
        <div className="flex gap-2">
          <button className="px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
            Trước
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg">1</button>
          <button className="px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
            2
          </button>
          <button className="px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
            Sau
          </button>
        </div>
      </div>
    </div>
  );
}
