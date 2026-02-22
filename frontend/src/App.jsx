import React, { useContext, useState, useEffect, useRef, useCallback } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation, Navigate, useNavigate } from 'react-router-dom';
import { Home, Users, FileText, Settings, Package, PieChart, Bell, Search, Hexagon, LogOut, ShieldCheck, Store, CreditCard, Brain, ArrowDownCircle, Shield, X, AlertTriangle, ShieldAlert, Info, ChevronRight } from 'lucide-react';
import axios from 'axios';

import AuthContext, { AuthProvider } from './context/AuthContext';
import Dashboard from './pages/Dashboard';
import Invoices from './pages/Invoices';
import CreateInvoice from './pages/CreateInvoice';
import Customers from './pages/Customers';
import Products from './pages/Products';
import Vendors from './pages/Vendors';
import Payments from './pages/Payments';
import Reports from './pages/Reports';
import AIInsights from './pages/AIInsights';
import RoleManagement from './pages/RoleManagement';
import SettingsPage from './pages/Settings';
import CreditDebitNotes from './pages/CreditDebitNotes';
import AuditLogs from './pages/AuditLogs';
import Login from './pages/Login';
import Register from './pages/Register';
import Landing from './pages/Landing';


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
    { name: 'AI Insights', path: '/ai', icon: <Brain size={20} /> },
    { name: 'Credit/Debit Notes', path: '/notes', icon: <ArrowDownCircle size={20} /> },
    { name: 'Audit Trail', path: '/audit', icon: <Shield size={20} />, adminOnly: true },
    { name: 'Team & Roles', path: '/roles', icon: <ShieldCheck size={20} />, adminOnly: true },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <div className="flex flex-col w-64 h-screen bg-white bg-opacity-70 backdrop-blur-xl border-r border-[#E5E7EB]/50 shadow-sm fixed z-10 transition-all duration-300">
      <div className="flex items-center gap-3 h-20 px-6 border-b border-[#E5E7EB]/50">
        <div className="bg-gradient-to-tr from-indigo-600 to-purple-600 p-2 rounded-xl text-white shadow-lg shadow-indigo-500/30">
          <Hexagon size={24} className="fill-white/20" />
        </div>
        <h1 className="text-xl font-black bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 font-space tracking-tight">GST.EDGE</h1>
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
  const { token } = useContext(AuthContext);
  const navigate = useNavigate();
  const hdrs = { headers: { Authorization: `Bearer ${token}` } };

  // ── Global Search ──
  const [query, setQuery] = useState('');
  const [results, setResults] = useState({ invoices: [], customers: [], products: [] });
  const [showResults, setShowResults] = useState(false);
  const [searching, setSearching] = useState(false);
  const searchRef = useRef(null);
  const debounceRef = useRef(null);

  // ── Notifications ──
  const [notifications, setNotifications] = useState([]);
  const [readIds, setReadIds] = useState(() => {
    try { return JSON.parse(localStorage.getItem('gst_notif_read') || '[]'); } catch { return []; }
  });
  const [showNotifs, setShowNotifs] = useState(false);
  const [notifsLoaded, setNotifsLoaded] = useState(false);
  const notifRef = useRef(null);

  // Persist read IDs to localStorage
  const saveReadIds = (ids) => {
    setReadIds(ids);
    localStorage.setItem('gst_notif_read', JSON.stringify(ids));
  };

  // Generate a stable ID for each notification (hash from title + type)
  const getNotifId = (n) => `${n.type}_${n.title}`.replace(/\s+/g, '_').toLowerCase();

  // Close dropdowns on outside click
  useEffect(() => {
    const handleClick = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) setShowResults(false);
      if (notifRef.current && !notifRef.current.contains(e.target)) setShowNotifs(false);
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  // Debounced search
  const handleSearch = useCallback((val) => {
    setQuery(val);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!val.trim()) { setResults({ invoices: [], customers: [], products: [] }); setShowResults(false); return; }

    debounceRef.current = setTimeout(async () => {
      setSearching(true);
      setShowResults(true);
      try {
        const q = val.toLowerCase();
        const [invRes, custRes, prodRes] = await Promise.all([
          axios.get('/api/invoices/', hdrs),
          axios.get('/api/customers/', hdrs),
          axios.get('/api/products/', hdrs),
        ]);
        setResults({
          invoices: invRes.data.filter(i =>
            i.invoice_number?.toLowerCase().includes(q) ||
            i.customer_details?.name?.toLowerCase().includes(q)
          ).slice(0, 5),
          customers: custRes.data.filter(c =>
            c.name?.toLowerCase().includes(q) ||
            c.gstin?.toLowerCase().includes(q) ||
            c.phone?.includes(q)
          ).slice(0, 5),
          products: prodRes.data.filter(p =>
            p.name?.toLowerCase().includes(q) ||
            p.hsn_sac?.includes(q)
          ).slice(0, 5),
        });
      } catch (e) { console.error(e); }
      finally { setSearching(false); }
    }, 300);
  }, [token]);

  const totalResults = results.invoices.length + results.customers.length + results.products.length;

  const handleResultClick = (type, item) => {
    setShowResults(false);
    setQuery('');
    if (type === 'invoice') navigate('/invoices');
    else if (type === 'customer') navigate('/customers');
    else if (type === 'product') navigate('/products');
  };

  // Fetch notifications (AI alerts)
  const fetchNotifications = async () => {
    try {
      const res = await axios.get('/api/ai/dashboard/', hdrs);
      setNotifications(res.data?.alerts || []);
      setNotifsLoaded(true);
    } catch (e) { console.error(e); setNotifsLoaded(true); }
  };

  const handleBellClick = () => {
    setShowNotifs(!showNotifs);
    if (!notifsLoaded) fetchNotifications();
  };

  const markAsRead = (notif, e) => {
    e.stopPropagation();
    const nid = getNotifId(notif);
    if (!readIds.includes(nid)) saveReadIds([...readIds, nid]);
  };

  const markAllAsRead = () => {
    const allIds = notifications.map(n => getNotifId(n));
    saveReadIds([...new Set([...readIds, ...allIds])]);
  };

  const isRead = (n) => readIds.includes(getNotifId(n));
  const unreadCount = notifications.filter(n => !isRead(n)).length;

  const severityIcon = (s) => {
    if (s === 'CRITICAL') return <ShieldAlert size={16} className="text-rose-500 shrink-0" />;
    if (s === 'WARNING') return <AlertTriangle size={16} className="text-amber-500 shrink-0" />;
    return <Info size={16} className="text-blue-500 shrink-0" />;
  };
  const severityBg = (s) => {
    if (s === 'CRITICAL') return 'bg-rose-50 border-rose-100';
    if (s === 'WARNING') return 'bg-amber-50 border-amber-100';
    return 'bg-blue-50 border-blue-100';
  };

  const criticalCount = notifications.filter(n => n.severity === 'CRITICAL' && !isRead(n)).length;
  const warningCount = notifications.filter(n => n.severity === 'WARNING' && !isRead(n)).length;

  return (
    <header className="h-20 bg-white/80 backdrop-blur-md border-b border-[#E5E7EB]/50 flex items-center justify-between px-8 sticky top-0 z-20">
      {/* Global Search */}
      <div ref={searchRef} className="relative w-96">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
        <input
          type="text"
          value={query}
          onChange={(e) => handleSearch(e.target.value)}
          onFocus={() => { if (query.trim()) setShowResults(true); }}
          placeholder="Search invoices, customers or products..."
          className="w-full bg-gray-50 border border-gray-200 text-sm rounded-full pl-10 pr-10 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 hover:bg-gray-100/50 transition-all font-medium text-gray-700 placeholder:text-gray-400 shadow-sm"
        />
        {query && (
          <button onClick={() => { setQuery(''); setShowResults(false); }} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
            <X size={16} />
          </button>
        )}

        {/* Search Results Dropdown */}
        {showResults && (
          <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-2xl shadow-2xl shadow-gray-200/50 overflow-hidden max-h-[420px] overflow-y-auto z-50">
            {searching ? (
              <div className="p-6 text-center text-gray-400 text-sm font-medium">Searching...</div>
            ) : totalResults === 0 ? (
              <div className="p-6 text-center text-gray-400 text-sm font-medium">No results for "{query}"</div>
            ) : (
              <>
                {results.invoices.length > 0 && (
                  <div>
                    <p className="px-4 pt-3 pb-1 text-[10px] font-bold text-gray-400 uppercase tracking-wider">Invoices</p>
                    {results.invoices.map(inv => (
                      <button key={inv.id} onClick={() => handleResultClick('invoice', inv)}
                        className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-indigo-50 transition-colors text-left">
                        <FileText size={16} className="text-indigo-500 shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 truncate">{inv.invoice_number}</p>
                          <p className="text-xs text-gray-500 truncate">{inv.customer_details?.name} — ₹{parseFloat(inv.total).toLocaleString('en-IN')}</p>
                        </div>
                        <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${inv.status === 'PAID' ? 'bg-emerald-50 text-emerald-600' :
                          inv.status === 'ISSUED' ? 'bg-blue-50 text-blue-600' :
                            inv.status === 'DRAFT' ? 'bg-gray-100 text-gray-600' :
                              'bg-amber-50 text-amber-600'
                          }`}>{inv.status}</span>
                        <ChevronRight size={14} className="text-gray-300" />
                      </button>
                    ))}
                  </div>
                )}
                {results.customers.length > 0 && (
                  <div className="border-t border-gray-100">
                    <p className="px-4 pt-3 pb-1 text-[10px] font-bold text-gray-400 uppercase tracking-wider">Customers</p>
                    {results.customers.map(c => (
                      <button key={c.id} onClick={() => handleResultClick('customer', c)}
                        className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-indigo-50 transition-colors text-left">
                        <Users size={16} className="text-emerald-500 shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 truncate">{c.name}</p>
                          <p className="text-xs text-gray-500 truncate">{c.gstin || c.phone}</p>
                        </div>
                        <ChevronRight size={14} className="text-gray-300" />
                      </button>
                    ))}
                  </div>
                )}
                {results.products.length > 0 && (
                  <div className="border-t border-gray-100">
                    <p className="px-4 pt-3 pb-1 text-[10px] font-bold text-gray-400 uppercase tracking-wider">Products</p>
                    {results.products.map(p => (
                      <button key={p.id} onClick={() => handleResultClick('product', p)}
                        className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-indigo-50 transition-colors text-left">
                        <Package size={16} className="text-orange-500 shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 truncate">{p.name}</p>
                          <p className="text-xs text-gray-500 truncate">HSN: {p.hsn_sac} — ₹{parseFloat(p.price).toLocaleString('en-IN')}</p>
                        </div>
                        <ChevronRight size={14} className="text-gray-300" />
                      </button>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>

      {/* Notification Bell */}
      <div ref={notifRef} className="relative">
        <button onClick={handleBellClick}
          className="relative p-2.5 text-gray-500 hover:bg-gray-100 hover:text-indigo-600 rounded-full transition-all group shadow-sm bg-white border border-gray-100">
          <Bell size={20} className={showNotifs ? 'text-indigo-600' : ''} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 min-w-[20px] h-5 bg-rose-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1 border-2 border-white animate-pulse">
              {unreadCount}
            </span>
          )}
          {!notifsLoaded && notifications.length === 0 && (
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full border border-white animate-pulse"></span>
          )}
        </button>

        {/* Notifications Dropdown */}
        {showNotifs && (
          <div className="absolute top-full right-0 mt-2 w-[420px] bg-white border border-gray-200 rounded-2xl shadow-2xl shadow-gray-200/50 overflow-hidden z-50">
            {/* Header */}
            <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
              <div>
                <h3 className="font-bold text-gray-900 text-sm">Notifications</h3>
                <p className="text-xs text-gray-400 mt-0.5">
                  {unreadCount === 0 ? 'All caught up' : `${unreadCount} unread${criticalCount > 0 ? ` · ${criticalCount} critical` : ''}`}
                </p>
              </div>
              {unreadCount > 0 && (
                <button onClick={markAllAsRead} className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 hover:underline transition-colors">
                  Mark all as read
                </button>
              )}
            </div>

            {/* Notification items */}
            <div className="max-h-[380px] overflow-y-auto">
              {!notifsLoaded ? (
                <div className="p-10 text-center"><div className="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-indigo-600 mx-auto"></div><p className="text-xs text-gray-400 mt-3">Loading alerts...</p></div>
              ) : notifications.length === 0 ? (
                <div className="p-10 text-center">
                  <Bell size={36} className="mx-auto text-gray-200 mb-3" />
                  <p className="text-sm font-semibold text-gray-500">No active alerts</p>
                  <p className="text-xs text-gray-400 mt-1">Your business is running smoothly</p>
                </div>
              ) : (
                notifications.map((n, i) => {
                  const read = isRead(n);
                  return (
                    <div key={i}
                      className={`flex items-start gap-3 px-5 py-3.5 border-b border-gray-50 transition-colors group relative ${read ? 'bg-gray-50/30' : 'bg-white hover:bg-indigo-50/30'}`}>
                      {/* Unread dot */}
                      {!read && <div className="absolute left-1.5 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-indigo-600"></div>}
                      <div className={`mt-0.5 p-1.5 rounded-lg border shrink-0 ${read ? 'opacity-40' : ''} ${severityBg(n.severity)}`}>
                        {severityIcon(n.severity)}
                      </div>
                      <div className={`flex-1 min-w-0 cursor-pointer ${read ? 'opacity-50' : ''}`}
                        onClick={() => { setShowNotifs(false); navigate('/ai'); }}>
                        <p className={`text-sm leading-snug ${read ? 'font-medium text-gray-500' : 'font-semibold text-gray-900'}`}>{n.title}</p>
                        <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{n.message}</p>
                        {n.action && <p className="text-[11px] text-indigo-600 font-medium mt-1.5 flex items-center gap-1"><ChevronRight size={10} />{n.action}</p>}
                      </div>
                      <div className="flex flex-col items-end gap-1.5 shrink-0">
                        <span className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded-full ${read ? 'opacity-40 ' : ''}${n.severity === 'CRITICAL' ? 'bg-rose-100 text-rose-700' :
                          n.severity === 'WARNING' ? 'bg-amber-100 text-amber-700' : 'bg-blue-100 text-blue-700'
                          }`}>{n.severity}</span>
                        {!read && (
                          <button onClick={(e) => markAsRead(n, e)}
                            className="opacity-0 group-hover:opacity-100 text-[10px] font-semibold text-gray-400 hover:text-indigo-600 transition-all flex items-center gap-0.5"
                            title="Mark as read">
                            <X size={11} /> Dismiss
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Footer */}
            {notifications.length > 0 && (
              <div className="flex items-center justify-between px-5 py-3 border-t border-gray-100 bg-gray-50/50">
                <span className="text-[11px] text-gray-400 font-medium">{notifications.length} total alert{notifications.length !== 1 ? 's' : ''}</span>
                <button onClick={() => { setShowNotifs(false); navigate('/ai'); }}
                  className="text-xs font-bold text-indigo-600 hover:text-indigo-800 hover:underline flex items-center gap-1 transition-colors">
                  View All Alerts <ChevronRight size={13} />
                </button>
              </div>
            )}
          </div>
        )}
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

const HomeSelector = () => {
  const { token, isLoading } = useContext(AuthContext);
  if (isLoading) return (
    <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC]">
      <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-600"></div>
    </div>
  );
  return token ? <PrivateRoute><Layout><Dashboard /></Layout></PrivateRoute> : <Landing />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          <Route path="/" element={<HomeSelector />} />
          <Route path="/invoices" element={<PrivateRoute><Layout><Invoices /></Layout></PrivateRoute>} />
          <Route path="/invoices/create" element={<PrivateRoute><Layout><CreateInvoice /></Layout></PrivateRoute>} />
          <Route path="/customers" element={<PrivateRoute><Layout><Customers /></Layout></PrivateRoute>} />
          <Route path="/products" element={<PrivateRoute><Layout><Products /></Layout></PrivateRoute>} />
          <Route path="/vendors" element={<PrivateRoute><Layout><Vendors /></Layout></PrivateRoute>} />
          <Route path="/payments" element={<PrivateRoute><Layout><Payments /></Layout></PrivateRoute>} />
          <Route path="/reports" element={<PrivateRoute><Layout><Reports /></Layout></PrivateRoute>} />
          <Route path="/ai" element={<PrivateRoute><Layout><AIInsights /></Layout></PrivateRoute>} />
          <Route path="/notes" element={<PrivateRoute><Layout><CreditDebitNotes /></Layout></PrivateRoute>} />
          <Route path="/audit" element={<PrivateRoute><Layout><AuditLogs /></Layout></PrivateRoute>} />
          <Route path="/roles" element={<PrivateRoute><Layout><RoleManagement /></Layout></PrivateRoute>} />
          <Route path="/settings" element={<PrivateRoute><Layout><SettingsPage /></Layout></PrivateRoute>} />
          <Route path="*" element={<PrivateRoute><Layout><div className="flex items-center justify-center h-full text-gray-400 text-lg font-medium">Coming soon</div></Layout></PrivateRoute>} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
