import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { ArrowUpRight, ArrowDownRight, CreditCard, DollarSign, Users, Activity, ExternalLink } from 'lucide-react';
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
    const [stats, setStats] = useState({ totalRevenue: 0, pendingAmount: 0, customersCount: 0, taxLiability: 0 });
    const [recentInvoices, setRecentInvoices] = useState([]);
    const [loading, setLoading] = useState(true);
    const { token } = useContext(AuthContext);

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                const hdrs = { headers: { Authorization: `Bearer ${token}` } };
                const [invRes, cusRes] = await Promise.all([
                    axios.get('/api/invoices/', hdrs),
                    axios.get('/api/customers/', hdrs)
                ]);

                const invoices = invRes.data;
                const customers = cusRes.data;

                // Calculations
                let totalRev = 0;
                let pendingAmt = 0;
                let taxLia = 0;

                invoices.forEach(inv => {
                    const total = parseFloat(inv.total);
                    const paid = parseFloat(inv.amount_paid || 0);

                    if (inv.status !== 'CANCELLED' && inv.status !== 'DRAFT') {
                        totalRev += paid;
                        pendingAmt += (total - paid);
                        taxLia += parseFloat(inv.cgst_total) + parseFloat(inv.sgst_total) + parseFloat(inv.igst_total);
                    }
                });

                setStats({
                    totalRevenue: totalRev,
                    pendingAmount: pendingAmt,
                    customersCount: customers.length,
                    taxLiability: taxLia
                });

                setRecentInvoices(invoices.slice(0, 4));
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
                    <button className="px-5 py-2.5 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl hover:bg-gray-50 hover:border-gray-300 transition-all shadow-sm">
                        Download Report
                    </button>
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
                        <StatCard
                            title="Revenue Collected"
                            value={formatCurrency(stats.totalRevenue)}
                            icon={DollarSign}
                            colorClass="bg-emerald-500"
                        />
                        <StatCard
                            title="Pending Receivables"
                            value={formatCurrency(stats.pendingAmount)}
                            icon={CreditCard}
                            colorClass="bg-rose-500"
                        />
                        <StatCard
                            title="Active Customers"
                            value={stats.customersCount}
                            icon={Users}
                            colorClass="bg-blue-500"
                        />
                        <StatCard
                            title="Tax Liability (GST)"
                            value={formatCurrency(stats.taxLiability)}
                            icon={Activity}
                            colorClass="bg-purple-500"
                        />
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        <div className="lg:col-span-2 bg-white rounded-3xl shadow-sm border border-gray-100 p-6 min-h-[400px]">
                            <h3 className="font-bold text-lg text-gray-900 mb-6 tracking-tight">Revenue Analytics</h3>
                            <div className="h-full flex items-center justify-center border-2 border-dashed border-gray-100 rounded-2xl bg-gray-50/50 min-h-[300px]">
                                <p className="text-gray-400 font-medium">Chart Visualization Coming Soon</p>
                            </div>
                        </div>
                        <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-6">
                            <div className="flex justify-between items-center mb-6">
                                <h3 className="font-bold text-lg text-gray-900 tracking-tight">Recent Invoices</h3>
                                <Link to="/invoices" className="text-sm text-indigo-600 font-semibold hover:text-indigo-700 flex items-center gap-1">
                                    View All <ExternalLink size={14} />
                                </Link>
                            </div>
                            <div className="space-y-5">
                                {recentInvoices.length === 0 ? (
                                    <p className="text-gray-500 text-sm text-center py-10">No recent invoices.</p>
                                ) : recentInvoices.map((inv, i) => {
                                    const initial = inv.customer_details?.name ? inv.customer_details.name.charAt(0).toUpperCase() : 'U';
                                    const pendingAmt = parseFloat(inv.total) - parseFloat(inv.amount_paid);

                                    return (
                                        <div key={inv.id} className="flex items-center justify-between group cursor-pointer border-b border-gray-50 pb-4 last:border-0 last:pb-0">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 font-bold group-hover:scale-110 transition-transform">
                                                    {initial}
                                                </div>
                                                <div>
                                                    <p className="text-sm font-semibold text-gray-900">{inv.invoice_number}</p>
                                                    <p className="text-xs text-gray-500 truncate w-32">{inv.customer_details?.name || 'Unknown'}</p>
                                                </div>
                                            </div>
                                            <div className="text-right">
                                                <p className="text-sm font-bold text-gray-900">{formatCurrency(inv.total)}</p>
                                                <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full ${pendingAmt > 0 ? 'text-amber-600 bg-amber-50' : 'text-emerald-600 bg-emerald-50'}`}>
                                                    {pendingAmt > 0 ? 'Pending' : 'Paid'}
                                                </span>
                                            </div>
                                        </div>
                                    )
                                })}
                            </div>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

export default Dashboard;
