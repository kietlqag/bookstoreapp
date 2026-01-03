import { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { Dashboard } from './components/Dashboard';
import { BooksManagement } from './components/BooksManagement';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'books':
        return <BooksManagement />;
      case 'orders':
        return (
          <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">Quản lý đơn hàng</h2>
            <p className="text-gray-500">Tính năng đang được phát triển...</p>
          </div>
        );
      case 'customers':
        return (
          <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">Quản lý khách hàng</h2>
            <p className="text-gray-500">Tính năng đang được phát triển...</p>
          </div>
        );
      case 'inventory':
        return (
          <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">Quản lý kho hàng</h2>
            <p className="text-gray-500">Tính năng đang được phát triển...</p>
          </div>
        );
      case 'analytics':
        return (
          <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">Thống kê chi tiết</h2>
            <p className="text-gray-500">Tính năng đang được phát triển...</p>
          </div>
        );
      case 'settings':
        return (
          <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">Cài đặt hệ thống</h2>
            <p className="text-gray-500">Tính năng đang được phát triển...</p>
          </div>
        );
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`fixed inset-0 z-50 lg:relative lg:z-0 ${sidebarOpen ? 'block' : 'hidden lg:block'}`}>
        {/* Overlay for mobile */}
        {sidebarOpen && (
          <div
            className="absolute inset-0 bg-black/50 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}
        <div className="relative">
          <Sidebar activeTab={activeTab} onTabChange={(tab) => {
            setActiveTab(tab);
            setSidebarOpen(false);
          }} />
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <Header onMenuClick={() => setSidebarOpen(!sidebarOpen)} />
        
        <main className="flex-1 p-6">
          {renderContent()}
        </main>
      </div>
    </div>
  );
}

export default App;
