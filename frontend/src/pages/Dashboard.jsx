import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { ArrowUpRight, ArrowDownRight, CreditCard, DollarSign, Users, Activity, ExternalLink, Package, AlertTriangle, TrendingUp } from 'lucide-react';
import { Link } from 'react-router-dom';

const StatCard = ({ title, value, change, trend, icon: Icon, colorClass }) => (
    <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100/50 hover:shadow-lg transition-all duration-300 relative overflow-hidden group">
        <div className={`absolute -right-4 -top-4 w-24 h-24 rounded-full ${colorClass} opacity-10 group-hover:scale-150 transition-transform duration-500`}></div>
        <div className="flex justify-between items-start mb-6 relative z-10">
            <div className="p-3 bg-gray-50 rounded-2xl group-hover:bg-indigo-50 transition-colors">
                <Icon className={`w-6 h-6 text-indigo-600`} />
            </div>
            {change && (
                <div className={`flex items-center gap-1 text-sm font-semibold px-2.5 py-1 rounded-full ${trend === 'up' ? 'text-emerald-600 bg-emerald-50' : 'text-rose-600 bg-rose-50'}`}>
                    {trend === 'up' ? <ArrowUpRight size={16} /> : <ArrowDownRight size={16} />}
                    {change}
                </div>
            )}
        </div>
        <div className="relative z-10">
            <h3 className="text-gray-500 text-sm font-medium tracking-wide">{title}</h3>
            <p className="text-3xl font-bold text-gray-900 mt-2 tracking-tight">{value}</p>
        </div>
    </div>
);

const Dashboard = () => {
    const [stats, setStats] = useState({ totalRevenue: 0, pendingAmount: 0, customersCount: 0, taxLiability: 0, productsCount: 0, lowStockCount: 0 });
    const [recentInvoices, setRecentInvoices] = useState([]);
    const [monthlyRevenue, setMonthlyRevenue] = useState([]);
    const [loading, setLoading] = useState(true);
    const { token } = useContext(AuthContext);

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                const hdrs = { headers: { Authorization: `Bearer ${token}` } };
                const [invRes, cusRes, prodRes] = await Promise.all([
                    axios.get('/api/invoices/', hdrs),
                    axios.get('/api/customers/', hdrs),
                    axios.get('/api/products/', hdrs)
                ]);

                const invoices = invRes.data;
                const customers = cusRes.data;
                const products = prodRes.data;

                let totalRev = 0, pendingAmt = 0, taxLia = 0;
                invoices.forEach(inv => {
                    const total = parseFloat(inv.total);
                    const paid = parseFloat(inv.amount_paid || 0);
                    if (inv.status !== 'CANCELLED' && inv.status !== 'DRAFT') {
                        totalRev += paid;
                        pendingAmt += (total - paid);
                        taxLia += parseFloat(inv.cgst_total) + parseFloat(inv.sgst_total) + parseFloat(inv.igst_total);
                    }
                });

                const lowStockCount = products.filter(p => p.is_low_stock).length;

                setStats({
                    totalRevenue: totalRev,
                    pendingAmount: pendingAmt,
                    customersCount: customers.length,
                    taxLiability: taxLia,
                    productsCount: products.length,
                    lowStockCount
                });

                setRecentInvoices(invoices.slice(0, 5));

                // Build monthly revenue for chart
                const monthly = {};
                const now = new Date();
                for (let i = 5; i >= 0; i--) {
                    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
                    const key = d.toLocaleString('default', { month: 'short', year: 'numeric' });
                    monthly[key] = 0;
                }
                invoices.forEach(inv => {
                    if (inv.status !== 'CANCELLED' && inv.status !== 'DRAFT') {
                        const d = new Date(inv.date);
                        const key = d.toLocaleString('default', { month: 'short', year: 'numeric' });
                        if (monthly[key] !== undefined) monthly[key] += parseFloat(inv.total);
                    }
                });
                setMonthlyRevenue(Object.entries(monthly).map(([month, revenue]) => ({ month, revenue })));
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        if (token) fetchDashboardData();
    }, [token]);

    const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(val);

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Overview</h2>
                    <p className="text-gray-500 mt-1 font-medium z-10 relative">Here's what's happening with your business today.</p>
                </div>
                <div className="flex gap-3">
                    <Link to="/reports" className="px-5 py-2.5 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl hover:bg-gray-50 hover:border-gray-300 transition-all shadow-sm inline-block">
                        View Reports
                    </Link>
                    <Link to="/invoices/create" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all transform hover:-translate-y-0.5 inline-block">
                        + New Invoice
                    </Link>
                </div>
            </div>

            {loading ? (
                <div className="py-20 flex justify-center">
                    <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div>
                </div>
            ) : (
                <>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <StatCard title="Revenue Collected" value={formatCurrency(stats.totalRevenue)} icon={DollarSign} colorClass="bg-emerald-500" />
                        <StatCard title="Pending Receivables" value={formatCurrency(stats.pendingAmount)} icon={CreditCard} colorClass="bg-rose-500" />
                        <StatCard title="Active Customers" value={stats.customersCount} icon={Users} colorClass="bg-blue-500" />
                        <StatCard title="Tax Liability (GST)" value={formatCurrency(stats.taxLiability)} icon={Activity} colorClass="bg-purple-500" />
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        {/* Revenue Chart — Circular Skeuomorphic */}
                        <div className="lg:col-span-2 bg-white rounded-3xl shadow-sm border border-gray-100 p-6">
                            <div className="flex justify-between items-center mb-6">
                                <h3 className="font-bold text-lg text-gray-900 tracking-tight flex items-center gap-2">
                                    <TrendingUp size={20} className="text-indigo-600" /> Revenue Analytics
                                </h3>
                                <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Last 6 Months</span>
                            </div>
                            {monthlyRevenue.length > 0 && monthlyRevenue.some(m => m.revenue > 0) ? (() => {
                                const total = monthlyRevenue.reduce((s, m) => s + m.revenue, 0);
                                const colors = [
                                    ['#6366f1', '#818cf8'], // indigo
                                    ['#8b5cf6', '#a78bfa'], // violet
                                    ['#06b6d4', '#22d3ee'], // cyan
                                    ['#10b981', '#34d399'], // emerald
                                    ['#f59e0b', '#fbbf24'], // amber
                                    ['#ec4899', '#f472b6'], // pink
                                ];
                                const size = 220;
                                const strokeWidth = 32;
                                const radius = (size - strokeWidth) / 2;
                                const circumference = 2 * Math.PI * radius;
                                let cumulativeOffset = 0;

                                return (
                                    <div className="flex flex-col items-center gap-6">
                                        {/* Donut Ring */}
                                        <div className="relative" style={{ width: size, height: size }}>
                                            <svg width={size} height={size} className="transform -rotate-90">
                                                {/* Background ring */}
                                                <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="#f1f5f9" strokeWidth={strokeWidth} />
                                                {/* Data arcs */}
                                                {monthlyRevenue.map((m, i) => {
                                                    const pct = total > 0 ? m.revenue / total : 0;
                                                    const dashLength = pct * circumference;
                                                    const gapLength = circumference - dashLength;
                                                    const offset = cumulativeOffset;
                                                    cumulativeOffset += dashLength;
                                                    if (m.revenue === 0) return null;
                                                    return (
                                                        <circle key={i}
                                                            cx={size / 2} cy={size / 2} r={radius}
                                                            fill="none"
                                                            stroke={colors[i % colors.length][0]}
                                                            strokeWidth={strokeWidth}
                                                            strokeDasharray={`${dashLength - 2} ${gapLength + 2}`}
                                                            strokeDashoffset={-offset}
                                                            strokeLinecap="round"
                                                            className="transition-all duration-700 hover:opacity-80"
                                                            style={{
                                                                filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))',
                                                                animation: `ring-fill-${i} 1s ease-out forwards`,
                                                            }}
                                                        >
                                                            <title>{m.month}: {formatCurrency(m.revenue)}</title>
                                                        </circle>
                                                    );
                                                })}
                                            </svg>
                                            {/* Center Label */}
                                            <div className="absolute inset-0 flex flex-col items-center justify-center">
                                                <p className="text-2xl font-black text-gray-900 tracking-tight">{formatCurrency(total)}</p>
                                                <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider mt-0.5">Total Revenue</p>
                                            </div>
                                        </div>

                                        {/* Legend */}
                                        <div className="grid grid-cols-3 gap-x-6 gap-y-3 w-full max-w-md">
                                            {monthlyRevenue.map((m, i) => {
                                                const pct = total > 0 ? ((m.revenue / total) * 100).toFixed(1) : '0.0';
                                                return (
                                                    <div key={i} className="flex items-center gap-2 group cursor-default">
                                                        <div className="w-3 h-3 rounded-full shrink-0 shadow-sm" style={{ background: `linear-gradient(135deg, ${colors[i % colors.length][0]}, ${colors[i % colors.length][1]})` }}></div>
                                                        <div className="min-w-0">
                                                            <p className="text-xs font-semibold text-gray-700 truncate">{m.month}</p>
                                                            <p className="text-[10px] text-gray-400 font-medium">{formatCurrency(m.revenue)} <span className="text-gray-300">({pct}%)</span></p>
                                                        </div>
                                                    </div>
                                                );
                                            })}
                                        </div>
                                    </div>
                                );
                            })() : (
                                <div className="h-56 flex flex-col items-center justify-center">
                                    <TrendingUp size={40} className="text-gray-200 mb-3" />
                                    <p className="text-gray-400 font-medium text-sm">Revenue chart will appear once you create invoices</p>
                                </div>
                            )}
                        </div>

                        {/* Recent Invoices + Quick Stats */}
                        <div className="space-y-6">
                            {/* Quick Inventory Alert */}
                            {stats.lowStockCount > 0 && (
                                <div className="bg-amber-50 rounded-2xl p-4 border border-amber-100 flex items-center gap-3">
                                    <AlertTriangle size={20} className="text-amber-500 shrink-0" />
                                    <div>
                                        <p className="font-bold text-amber-800 text-sm">{stats.lowStockCount} product(s) low on stock</p>
                                        <Link to="/products" className="text-xs font-semibold text-amber-600 hover:underline">View products →</Link>
                                    </div>
                                </div>
                            )}

                            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-6">
                                <div className="flex justify-between items-center mb-6">
                                    <h3 className="font-bold text-lg text-gray-900 tracking-tight">Recent Invoices</h3>
                                    <Link to="/invoices" className="text-sm text-indigo-600 font-semibold hover:text-indigo-700 flex items-center gap-1">
                                        View All <ExternalLink size={14} />
                                    </Link>
                                </div>
                                <div className="space-y-4">
                                    {recentInvoices.length === 0 ? (
                                        <p className="text-gray-500 text-sm text-center py-10">No recent invoices.</p>
                                    ) : recentInvoices.map((inv) => {
                                        const initial = inv.customer_details?.name ? inv.customer_details.name.charAt(0).toUpperCase() : 'U';
                                        const pendingAmt = parseFloat(inv.total) - parseFloat(inv.amount_paid);
                                        return (
                                            <div key={inv.id} className="flex items-center justify-between group border-b border-gray-50 pb-3 last:border-0 last:pb-0">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-9 h-9 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 font-bold text-sm group-hover:scale-110 transition-transform">
                                                        {initial}
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-semibold text-gray-900">{inv.invoice_number}</p>
                                                        <p className="text-xs text-gray-500 truncate w-28">{inv.customer_details?.name || 'Unknown'}</p>
                                                    </div>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-sm font-bold text-gray-900">{formatCurrency(inv.total)}</p>
                                                    <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full ${pendingAmt > 0 ? 'text-amber-600 bg-amber-50' : 'text-emerald-600 bg-emerald-50'}`}>
                                                        {inv.status}
                                                    </span>
                                                </div>
                                            </div>
                                        )
                                    })}
                                </div>
                            </div>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

export default Dashboard;
