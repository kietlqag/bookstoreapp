import { DollarSign, ShoppingCart, BookOpen, TrendingUp, Package } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const revenueData = [
  { month: 'T1', revenue: 45000000, orders: 234 },
  { month: 'T2', revenue: 52000000, orders: 289 },
  { month: 'T3', revenue: 48000000, orders: 267 },
  { month: 'T4', revenue: 61000000, orders: 345 },
  { month: 'T5', revenue: 55000000, orders: 312 },
  { month: 'T6', revenue: 67000000, orders: 389 },
];

const topBooks = [
  { title: 'Đắc Nhân Tâm', author: 'Dale Carnegie', sold: 1234, revenue: 98720000 },
  { title: 'Nhà Giả Kim', author: 'Paulo Coelho', sold: 987, revenue: 78960000 },
  { title: 'Sapiens', author: 'Yuval Noah Harari', sold: 876, revenue: 87600000 },
  { title: 'Atomic Habits', author: 'James Clear', sold: 765, revenue: 76500000 },
  { title: 'Think and Grow Rich', author: 'Napoleon Hill', sold: 654, revenue: 65400000 },
];

const recentOrders = [
  { id: 'DH001', customer: 'Nguyễn Văn A', items: 3, total: 450000, status: 'completed' },
  { id: 'DH002', customer: 'Trần Thị B', items: 2, total: 280000, status: 'pending' },
  { id: 'DH003', customer: 'Lê Văn C', items: 5, total: 750000, status: 'shipping' },
  { id: 'DH004', customer: 'Phạm Thị D', items: 1, total: 120000, status: 'completed' },
  { id: 'DH005', customer: 'Hoàng Văn E', items: 4, total: 520000, status: 'pending' },
];

export function Dashboard() {
  const stats = [
    {
      title: 'Doanh thu tháng',
      value: '67,000,000₫',
      change: '+12.5%',
      icon: DollarSign,
      color: 'bg-green-500',
    },
    {
      title: 'Đơn hàng',
      value: '389',
      change: '+8.2%',
      icon: ShoppingCart,
      color: 'bg-blue-500',
    },
    {
      title: 'Sách bán ra',
      value: '1,245',
      change: '+15.3%',
      icon: BookOpen,
      color: 'bg-purple-500',
    },
    {
      title: 'Tồn kho',
      value: '12,456',
      change: '-2.4%',
      icon: Package,
      color: 'bg-orange-500',
    },
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'shipping':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'pending':
        return 'Chờ xử lý';
      case 'shipping':
        return 'Đang giao';
      default:
        return status;
    }
  };

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="bg-white rounded-xl p-6 border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <div className={`${stat.color} p-3 rounded-lg`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
                <div className="flex items-center gap-1 text-sm">
                  <TrendingUp className={`w-4 h-4 ${stat.change.startsWith('+') ? 'text-green-600' : 'text-red-600'}`} />
                  <span className={stat.change.startsWith('+') ? 'text-green-600' : 'text-red-600'}>
                    {stat.change}
                  </span>
                </div>
              </div>
              <h3 className="text-2xl font-semibold text-gray-900 mb-1">{stat.value}</h3>
              <p className="text-sm text-gray-500">{stat.title}</p>
            </div>
          );
        })}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Chart */}
        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Doanh thu 6 tháng gần đây</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" stroke="#6b7280" />
              <YAxis stroke="#6b7280" />
              <Tooltip 
                formatter={(value: number) => [`${(value / 1000000).toFixed(1)}M₫`, 'Doanh thu']}
                contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb' }}
              />
              <Line 
                type="monotone" 
                dataKey="revenue" 
                stroke="#3b82f6" 
                strokeWidth={3}
                dot={{ fill: '#3b82f6', r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Orders Chart */}
        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Số đơn hàng theo tháng</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" stroke="#6b7280" />
              <YAxis stroke="#6b7280" />
              <Tooltip 
                formatter={(value: number) => [`${value} đơn`, 'Số lượng']}
                contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb' }}
              />
              <Bar dataKey="orders" fill="#8b5cf6" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Tables */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Books */}
        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Sách bán chạy</h3>
          <div className="space-y-4">
            {topBooks.map((book, index) => (
              <div key={index} className="flex items-center justify-between pb-4 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">{book.title}</h4>
                  <p className="text-sm text-gray-500">{book.author}</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-gray-900">{book.sold} quyển</p>
                  <p className="text-sm text-gray-500">{(book.revenue / 1000000).toFixed(1)}M₫</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Orders */}
        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Đơn hàng gần đây</h3>
          <div className="space-y-4">
            {recentOrders.map((order) => (
              <div key={order.id} className="flex items-center justify-between pb-4 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-medium text-gray-900">{order.id}</h4>
                    <span className={`px-2 py-0.5 rounded-full text-xs ${getStatusColor(order.status)}`}>
                      {getStatusText(order.status)}
                    </span>
                  </div>
                  <p className="text-sm text-gray-500">{order.customer} • {order.items} sản phẩm</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-gray-900">{order.total.toLocaleString()}₫</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
