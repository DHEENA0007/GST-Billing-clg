import React, { useContext } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation, Navigate } from 'react-router-dom';
import { Home, Users, FileText, Settings, Package, PieChart, Bell, Search, Hexagon, LogOut, ShieldCheck, Store, CreditCard } from 'lucide-react';

import AuthContext, { AuthProvider } from './context/AuthContext';
import Dashboard from './pages/Dashboard';
import Invoices from './pages/Invoices';
import CreateInvoice from './pages/CreateInvoice';
import Customers from './pages/Customers';
import Products from './pages/Products';
import Vendors from './pages/Vendors';
import Payments from './pages/Payments';
import Reports from './pages/Reports';
import RoleManagement from './pages/RoleManagement';
import SettingsPage from './pages/Settings';
import Login from './pages/Login';
import Register from './pages/Register';

const PrivateRoute = ({ children }) => {
  const { user, token, isLoading } = useContext(AuthContext);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC]">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return token ? children : <Navigate to="/login" />;
};

const Sidebar = () => {
  const location = useLocation();
  const { user, logout } = useContext(AuthContext);

  const navItems = [
    { name: 'Dashboard', path: '/', icon: <Home size={20} /> },
    { name: 'Invoices', path: '/invoices', icon: <FileText size={20} /> },
    { name: 'Customers', path: '/customers', icon: <Users size={20} /> },
    { name: 'Products', path: '/products', icon: <Package size={20} /> },
    { name: 'Vendors', path: '/vendors', icon: <Store size={20} /> },
    { name: 'Payments', path: '/payments', icon: <CreditCard size={20} /> },
    { name: 'Reports', path: '/reports', icon: <PieChart size={20} /> },
    { name: 'Team & Roles', path: '/roles', icon: <ShieldCheck size={20} />, adminOnly: true },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <div className="flex flex-col w-64 h-screen bg-white bg-opacity-70 backdrop-blur-xl border-r border-[#E5E7EB]/50 shadow-sm fixed z-10 transition-all duration-300">
      <div className="flex items-center gap-3 h-20 px-6 border-b border-[#E5E7EB]/50">
        <div className="bg-gradient-to-tr from-indigo-600 to-purple-600 p-2 rounded-xl text-white shadow-lg shadow-indigo-500/30">
          <Hexagon size={24} className="fill-white/20" />
        </div>
        <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600">GST Billing</h1>
      </div>
      <div className="flex-1 overflow-y-auto py-6 px-4 space-y-1.5">
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 px-2">Main Menu</p>
        {navItems.map((item) => {
          if (item.adminOnly && user?.profile?.role !== 'ADMIN') return null;

          const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
          return (
            <Link
              key={item.name}
              to={item.path}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-300 group relative overflow-hidden ${isActive
                ? 'bg-indigo-50 text-indigo-600 font-medium'
                : 'text-gray-500 hover:text-gray-900 hover:bg-gray-50/80'
                }`}
            >
              {isActive && (
                <div className="absolute left-0 top-0 bottom-0 w-1 bg-indigo-600 rounded-r-lg shadow-[0_0_10px_rgba(79,70,229,0.5)]"></div>
              )}
              <span className={`transition-transform duration-300 ${isActive ? 'scale-110 shadow-sm' : 'group-hover:scale-110'}`}>
                {item.icon}
              </span>
              <span className="relative z-10">{item.name}</span>
            </Link>
          );
        })}
      </div>
      <div className="p-4 border-t border-[#E5E7EB]/50">
        <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-100 shadow-sm group">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-100 to-purple-100 flex-shrink-0 flex items-center justify-center text-indigo-700 font-bold border border-indigo-200 shadow-inner">
              {user?.username ? user.username.charAt(0).toUpperCase() : 'U'}
            </div>
            <div className="flex-1 overflow-hidden">
              <p className="text-sm font-semibold text-gray-900 truncate tracking-tight">{user?.first_name || user?.username || 'User'}</p>
              <p className="text-[10px] uppercase tracking-wider font-bold text-indigo-600">{user?.profile?.role || 'Guest'}</p>
            </div>
          </div>
          <button onClick={logout} className="p-1.5 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer" title="Logout">
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};

const Header = () => {
  return (
    <header className="h-20 bg-white/80 backdrop-blur-md border-b border-[#E5E7EB]/50 flex items-center justify-between px-8 sticky top-0 z-10">
      <div className="flex items-center gap-4 w-96">
        <div className="relative w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input
            type="text"
            placeholder="Search invoices, customers or products..."
            className="w-full bg-gray-50 border border-gray-200 text-sm rounded-full pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 hover:bg-gray-100/50 transition-all font-medium text-gray-700 placeholder:text-gray-400 shadow-sm"
          />
        </div>
      </div>
      <div className="flex items-center gap-4">
        <button className="relative p-2 text-gray-500 hover:bg-gray-100 hover:text-indigo-600 rounded-full transition-all group shadow-sm bg-white border border-gray-100">
          <Bell size={20} className="group-hover:animate-swing" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full border border-white animate-pulse"></span>
        </button>
      </div>
    </header>
  );
};

const Layout = ({ children }) => {
  return (
    <div className="flex min-h-screen bg-[#F8FAFC] font-sans text-gray-800 antialiased selection:bg-indigo-100 selection:text-indigo-900">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col relative overflow-hidden">
        <div className="absolute top-0 left-0 right-0 h-96 bg-gradient-to-b from-indigo-50/50 to-transparent pointer-events-none -z-10"></div>
        <Header />
        <main className="flex-1 p-8 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          <Route path="/" element={<PrivateRoute><Layout><Dashboard /></Layout></PrivateRoute>} />
          <Route path="/invoices" element={<PrivateRoute><Layout><Invoices /></Layout></PrivateRoute>} />
          <Route path="/invoices/create" element={<PrivateRoute><Layout><CreateInvoice /></Layout></PrivateRoute>} />
          <Route path="/customers" element={<PrivateRoute><Layout><Customers /></Layout></PrivateRoute>} />
          <Route path="/products" element={<PrivateRoute><Layout><Products /></Layout></PrivateRoute>} />
          <Route path="/vendors" element={<PrivateRoute><Layout><Vendors /></Layout></PrivateRoute>} />
          <Route path="/payments" element={<PrivateRoute><Layout><Payments /></Layout></PrivateRoute>} />
          <Route path="/reports" element={<PrivateRoute><Layout><Reports /></Layout></PrivateRoute>} />
          <Route path="/roles" element={<PrivateRoute><Layout><RoleManagement /></Layout></PrivateRoute>} />
          <Route path="/settings" element={<PrivateRoute><Layout><SettingsPage /></Layout></PrivateRoute>} />
          <Route path="*" element={<PrivateRoute><Layout><div className="flex items-center justify-center h-full text-gray-400 text-lg font-medium">Coming soon</div></Layout></PrivateRoute>} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
