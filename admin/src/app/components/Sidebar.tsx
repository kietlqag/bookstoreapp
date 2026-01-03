import { 
  LayoutDashboard, 
  BookOpen, 
  ShoppingCart, 
  Users, 
  Package, 
  Settings,
  ChartLine 
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export function Sidebar({ activeTab, onTabChange }: SidebarProps) {
  const menuItems = [
    { id: 'dashboard', label: 'Tổng quan', icon: LayoutDashboard },
    { id: 'books', label: 'Quản lý sách', icon: BookOpen },
    { id: 'orders', label: 'Đơn hàng', icon: ShoppingCart },
    { id: 'customers', label: 'Khách hàng', icon: Users },
    { id: 'inventory', label: 'Kho hàng', icon: Package },
    { id: 'analytics', label: 'Thống kê', icon: ChartLine },
    { id: 'settings', label: 'Cài đặt', icon: Settings },
  ];

  return (
    <aside className="w-64 bg-white border-r border-gray-200 min-h-screen">
      <div className="p-6">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
            <BookOpen className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-gray-900">BookStore</h1>
            <p className="text-sm text-gray-500">Admin Panel</p>
          </div>
        </div>
        
        <nav className="space-y-1">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            
            return (
              <button
                key={item.id}
                onClick={() => onTabChange(item.id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-blue-50 text-blue-600'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>
    </aside>
  );
}
