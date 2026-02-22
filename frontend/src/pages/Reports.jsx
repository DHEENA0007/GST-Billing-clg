import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { PieChart, TrendingUp, TrendingDown, DollarSign, FileText, Package, Users, AlertTriangle, BarChart3, ArrowUpRight, Download } from 'lucide-react';

const Reports = () => {
    const { token } = useContext(AuthContext);
    const [activeTab, setActiveTab] = useState('sales');
    const [loading, setLoading] = useState(false);
    const [salesData, setSalesData] = useState(null);
    const [purchaseData, setPurchaseData] = useState(null);
    const [gstSummary, setGstSummary] = useState(null);
    const [profitLoss, setProfitLoss] = useState(null);
    const [outstanding, setOutstanding] = useState([]);
    const [stockReport, setStockReport] = useState([]);
    const [taxLiability, setTaxLiability] = useState([]);
    const [gstr1, setGstr1] = useState(null);
    const [gstr3b, setGstr3b] = useState(null);

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };
    const fmt = (v) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(v || 0);

    useEffect(() => { fetchReport(activeTab); }, [activeTab]);

    const fetchReport = async (tab) => {
        setLoading(true);
        try {
            switch (tab) {
                case 'sales':
                    const s = await axios.get('/api/reports/sales_report/', hdrs);
                    setSalesData(s.data);
                    break;
                case 'purchase':
                    const p = await axios.get('/api/reports/purchase_report/', hdrs);
                    setPurchaseData(p.data);
                    break;
                case 'gst':
                    const g = await axios.get('/api/reports/gst_summary/', hdrs);
                    setGstSummary(g.data);
                    break;
                case 'pnl':
                    const pl = await axios.get('/api/reports/profit_loss/', hdrs);
                    setProfitLoss(pl.data);
                    break;
                case 'outstanding':
                    const o = await axios.get('/api/reports/customer_outstanding/', hdrs);
                    setOutstanding(o.data);
                    break;
                case 'stock':
                    const st = await axios.get('/api/reports/stock_report/', hdrs);
                    setStockReport(st.data);
                    break;
                case 'tax':
                    const t = await axios.get('/api/reports/tax_liability/', hdrs);
                    setTaxLiability(t.data);
                    break;
                case 'gstr1':
                    const g1 = await axios.get('/api/reports/gstr1/', hdrs);
                    setGstr1(g1.data);
                    break;
                case 'gstr3b':
                    const g3 = await axios.get('/api/reports/gstr3b/', hdrs);
                    setGstr3b(g3.data);
                    break;
            }
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const tabs = [
        { id: 'sales', label: 'Sales', icon: <TrendingUp size={16} /> },
        { id: 'purchase', label: 'Purchase', icon: <TrendingDown size={16} /> },
        { id: 'gst', label: 'GST Summary', icon: <PieChart size={16} /> },
        { id: 'pnl', label: 'Profit & Loss', icon: <BarChart3 size={16} /> },
        { id: 'outstanding', label: 'Outstanding', icon: <Users size={16} /> },
        { id: 'stock', label: 'Stock', icon: <Package size={16} /> },
        { id: 'tax', label: 'Tax Liability', icon: <DollarSign size={16} /> },
        { id: 'gstr1', label: 'GSTR-1', icon: <FileText size={16} /> },
        { id: 'gstr3b', label: 'GSTR-3B', icon: <FileText size={16} /> },
    ];

    const StatBox = ({ label, value, color = 'indigo' }) => (
        <div className={`bg-${color}-50 rounded-2xl p-5 border border-${color}-100`}>
            <p className="text-sm text-gray-500 font-medium mb-1">{label}</p>
            <p className={`text-2xl font-bold text-${color}-700 tracking-tight`}>{value}</p>
        </div>
    );

    const renderContent = () => {
        if (loading) return <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>;

        switch (activeTab) {
            case 'sales':
                return salesData && (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Total Sales</p>
                            <p className="text-2xl font-bold text-emerald-700">{fmt(salesData.total_sales)}</p>
                        </div>
                        <div className="bg-blue-50 rounded-2xl p-6 border border-blue-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Amount Collected</p>
                            <p className="text-2xl font-bold text-blue-700">{fmt(salesData.total_collected)}</p>
                        </div>
                        <div className="bg-purple-50 rounded-2xl p-6 border border-purple-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Invoices</p>
                            <p className="text-2xl font-bold text-purple-700">{salesData.invoice_count}</p>
                        </div>
                        <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">CGST Collected</p>
                            <p className="text-2xl font-bold text-amber-700">{fmt(salesData.total_cgst)}</p>
                        </div>
                        <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">SGST Collected</p>
                            <p className="text-2xl font-bold text-amber-700">{fmt(salesData.total_sgst)}</p>
                        </div>
                        <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">IGST Collected</p>
                            <p className="text-2xl font-bold text-amber-700">{fmt(salesData.total_igst)}</p>
                        </div>
                    </div>
                );

            case 'purchase':
                return purchaseData && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <div className="bg-rose-50 rounded-2xl p-6 border border-rose-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Total Purchases</p>
                            <p className="text-2xl font-bold text-rose-700">{fmt(purchaseData.total_purchases)}</p>
                        </div>
                        <div className="bg-blue-50 rounded-2xl p-6 border border-blue-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Tax Paid</p>
                            <p className="text-2xl font-bold text-blue-700">{fmt(purchaseData.total_tax)}</p>
                        </div>
                        <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Input Tax Credit</p>
                            <p className="text-2xl font-bold text-emerald-700">{fmt(purchaseData.total_itc)}</p>
                        </div>
                        <div className="bg-purple-50 rounded-2xl p-6 border border-purple-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Purchase Orders</p>
                            <p className="text-2xl font-bold text-purple-700">{purchaseData.purchase_count}</p>
                        </div>
                    </div>
                );

            case 'gst':
                return gstSummary && (
                    <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                                <p className="text-sm text-gray-500 font-medium mb-1">Output CGST</p>
                                <p className="text-2xl font-bold text-amber-700">{fmt(gstSummary.output_tax.cgst)}</p>
                            </div>
                            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                                <p className="text-sm text-gray-500 font-medium mb-1">Output SGST</p>
                                <p className="text-2xl font-bold text-amber-700">{fmt(gstSummary.output_tax.sgst)}</p>
                            </div>
                            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                                <p className="text-sm text-gray-500 font-medium mb-1">Output IGST</p>
                                <p className="text-2xl font-bold text-amber-700">{fmt(gstSummary.output_tax.igst)}</p>
                            </div>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                                <p className="text-sm text-gray-500 font-medium mb-1">Input Tax Credit</p>
                                <p className="text-2xl font-bold text-emerald-700">{fmt(gstSummary.input_tax_credit)}</p>
                            </div>
                            <div className={`rounded-2xl p-6 border ${gstSummary.net_tax_liability > 0 ? 'bg-rose-50 border-rose-100' : 'bg-emerald-50 border-emerald-100'}`}>
                                <p className="text-sm text-gray-500 font-medium mb-1">Net Tax Liability</p>
                                <p className={`text-2xl font-bold ${gstSummary.net_tax_liability > 0 ? 'text-rose-700' : 'text-emerald-700'}`}>{fmt(gstSummary.net_tax_liability)}</p>
                            </div>
                        </div>
                    </div>
                );

            case 'pnl':
                return profitLoss && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Revenue</p>
                            <p className="text-2xl font-bold text-emerald-700">{fmt(profitLoss.revenue)}</p>
                        </div>
                        <div className="bg-rose-50 rounded-2xl p-6 border border-rose-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Expenses</p>
                            <p className="text-2xl font-bold text-rose-700">{fmt(profitLoss.expenses)}</p>
                        </div>
                        <div className={`rounded-2xl p-6 border ${profitLoss.gross_profit >= 0 ? 'bg-emerald-50 border-emerald-100' : 'bg-rose-50 border-rose-100'}`}>
                            <p className="text-sm text-gray-500 font-medium mb-1">Gross Profit</p>
                            <p className={`text-2xl font-bold ${profitLoss.gross_profit >= 0 ? 'text-emerald-700' : 'text-rose-700'}`}>{fmt(profitLoss.gross_profit)}</p>
                        </div>
                        <div className="bg-indigo-50 rounded-2xl p-6 border border-indigo-100">
                            <p className="text-sm text-gray-500 font-medium mb-1">Profit Margin</p>
                            <p className="text-2xl font-bold text-indigo-700">{profitLoss.profit_margin}%</p>
                        </div>
                    </div>
                );

            case 'outstanding':
                return (
                    <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                        {outstanding.length === 0 ? (
                            <div className="p-12 text-center text-gray-500">No outstanding receivables</div>
                        ) : (
                            <table className="w-full text-left">
                                <thead><tr className="bg-gray-50 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                                    <th className="p-4 pl-6">Customer</th><th className="p-4">GSTIN</th><th className="p-4 text-right pr-6">Outstanding</th>
                                </tr></thead>
                                <tbody className="divide-y divide-gray-50">
                                    {outstanding.map(c => (
                                        <tr key={c.id} className="hover:bg-gray-50/50">
                                            <td className="p-4 pl-6 font-semibold text-gray-900">{c.name}</td>
                                            <td className="p-4 text-gray-600">{c.gstin || 'N/A'}</td>
                                            <td className="p-4 text-right pr-6 font-bold text-rose-600">{fmt(c.outstanding)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                );

            case 'stock':
                return (
                    <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                        {stockReport.length === 0 ? (
                            <div className="p-12 text-center text-gray-500">No products in inventory</div>
                        ) : (
                            <table className="w-full text-left">
                                <thead><tr className="bg-gray-50 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                                    <th className="p-4 pl-6">Product</th><th className="p-4">HSN</th><th className="p-4">Stock</th><th className="p-4">Value</th><th className="p-4">Status</th>
                                </tr></thead>
                                <tbody className="divide-y divide-gray-50">
                                    {stockReport.map(p => (
                                        <tr key={p.id} className="hover:bg-gray-50/50">
                                            <td className="p-4 pl-6 font-semibold text-gray-900">{p.name}</td>
                                            <td className="p-4 text-gray-600">{p.hsn_sac}</td>
                                            <td className="p-4 font-medium">{p.stock} units</td>
                                            <td className="p-4 font-bold text-gray-900">{fmt(p.stock_value)}</td>
                                            <td className="p-4">
                                                {p.is_low_stock ? (
                                                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-50 text-rose-600 border border-rose-100">
                                                        <AlertTriangle size={12} /> Low Stock
                                                    </span>
                                                ) : (
                                                    <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-600 border border-emerald-100">In Stock</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                );

            case 'tax':
                return (
                    <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                        {taxLiability.length === 0 ? (
                            <div className="p-12 text-center text-gray-500">No tax data for this period</div>
                        ) : (
                            <table className="w-full text-left">
                                <thead><tr className="bg-gray-50 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                                    <th className="p-4 pl-6">GST Rate</th><th className="p-4">Taxable Value</th><th className="p-4">CGST</th><th className="p-4">SGST</th><th className="p-4">IGST</th><th className="p-4 pr-6">Total Tax</th>
                                </tr></thead>
                                <tbody className="divide-y divide-gray-50">
                                    {taxLiability.map((r, i) => (
                                        <tr key={i} className="hover:bg-gray-50/50">
                                            <td className="p-4 pl-6 font-bold text-indigo-600">{r.gst_rate}%</td>
                                            <td className="p-4">{fmt(r.taxable_value)}</td>
                                            <td className="p-4">{fmt(r.cgst)}</td>
                                            <td className="p-4">{fmt(r.sgst)}</td>
                                            <td className="p-4">{fmt(r.igst)}</td>
                                            <td className="p-4 pr-6 font-bold text-gray-900">{fmt(r.total_tax)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                );

            case 'gstr1':
                return gstr1 && (
                    <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div className="bg-indigo-50 rounded-2xl p-6 border border-indigo-100">
                                <p className="text-sm text-gray-500 mb-1">Period</p>
                                <p className="text-lg font-bold text-indigo-700">{gstr1.period}</p>
                            </div>
                            <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                                <p className="text-sm text-gray-500 mb-1">Total Taxable Value</p>
                                <p className="text-2xl font-bold text-emerald-700">{fmt(gstr1.total_taxable_value)}</p>
                            </div>
                            <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                                <p className="text-sm text-gray-500 mb-1">Total Tax</p>
                                <p className="text-2xl font-bold text-amber-700">{fmt(gstr1.total_tax)}</p>
                            </div>
                        </div>
                        <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                            <table className="w-full text-left">
                                <thead><tr className="bg-gray-50 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                                    <th className="p-4 pl-6">Invoice No</th><th className="p-4">Date</th><th className="p-4">Customer</th><th className="p-4">GSTIN</th><th className="p-4">Taxable</th><th className="p-4">CGST</th><th className="p-4">SGST</th><th className="p-4">IGST</th><th className="p-4 pr-6">Total</th>
                                </tr></thead>
                                <tbody className="divide-y divide-gray-50">
                                    {gstr1.invoices.map((inv, i) => (
                                        <tr key={i} className="hover:bg-gray-50/50 text-sm">
                                            <td className="p-4 pl-6 font-semibold">{inv.invoice_number}</td>
                                            <td className="p-4">{inv.invoice_date}</td>
                                            <td className="p-4">{inv.customer_name}</td>
                                            <td className="p-4 text-gray-600">{inv.customer_gstin}</td>
                                            <td className="p-4">{fmt(inv.taxable_value)}</td>
                                            <td className="p-4">{fmt(inv.cgst)}</td>
                                            <td className="p-4">{fmt(inv.sgst)}</td>
                                            <td className="p-4">{fmt(inv.igst)}</td>
                                            <td className="p-4 pr-6 font-bold">{fmt(inv.total)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                );

            case 'gstr3b':
                return gstr3b && (
                    <div className="space-y-6">
                        <div className="bg-indigo-50 rounded-2xl p-6 border border-indigo-100">
                            <p className="text-sm text-gray-500 mb-1">Filing Period</p>
                            <p className="text-lg font-bold text-indigo-700">{gstr3b.period}</p>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="bg-white rounded-2xl p-6 border border-gray-100 space-y-4">
                                <h4 className="font-bold text-gray-900 text-lg">Outward Supplies (Output Tax)</h4>
                                <div className="space-y-3">
                                    <div className="flex justify-between"><span className="text-gray-500">Taxable Value</span><span className="font-bold">{fmt(gstr3b.outward_supplies.taxable_value)}</span></div>
                                    <div className="flex justify-between"><span className="text-gray-500">CGST</span><span className="font-bold">{fmt(gstr3b.outward_supplies.cgst)}</span></div>
                                    <div className="flex justify-between"><span className="text-gray-500">SGST</span><span className="font-bold">{fmt(gstr3b.outward_supplies.sgst)}</span></div>
                                    <div className="flex justify-between"><span className="text-gray-500">IGST</span><span className="font-bold">{fmt(gstr3b.outward_supplies.igst)}</span></div>
                                    <div className="flex justify-between pt-3 border-t"><span className="font-bold text-gray-900">Total Tax</span><span className="font-bold text-amber-600">{fmt(gstr3b.outward_supplies.total_tax)}</span></div>
                                </div>
                            </div>
                            <div className="space-y-6">
                                <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100">
                                    <p className="text-sm text-gray-500 mb-1">Input Tax Credit</p>
                                    <p className="text-2xl font-bold text-emerald-700">{fmt(gstr3b.input_tax_credit)}</p>
                                </div>
                                <div className={`rounded-2xl p-6 border ${gstr3b.net_tax_payable > 0 ? 'bg-rose-50 border-rose-100' : 'bg-emerald-50 border-emerald-100'}`}>
                                    <p className="text-sm text-gray-500 mb-1">Net Tax Payable</p>
                                    <p className={`text-2xl font-bold ${gstr3b.net_tax_payable > 0 ? 'text-rose-700' : 'text-emerald-700'}`}>{fmt(gstr3b.net_tax_payable)}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                );
        }
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <BarChart3 className="text-indigo-600" size={28} />
                        Reports & Analytics
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Comprehensive business insights, GST filings and financial data.</p>
                </div>
            </div>

            <div className="flex gap-2 flex-wrap">
                {tabs.map(t => (
                    <button key={t.id} onClick={() => setActiveTab(t.id)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${activeTab === t.id
                                ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/20'
                                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
                            }`}>
                        {t.icon} {t.label}
                    </button>
                ))}
            </div>

            <div className="min-h-[300px]">
                {renderContent()}
            </div>
        </div>
    );
};

export default Reports;
