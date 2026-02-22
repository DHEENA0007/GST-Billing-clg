import React, { useState, useEffect, useContext } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Plus, Download, Filter, FileText, XCircle, CheckCircle, Send, Eye, Search } from 'lucide-react';

const Invoices = () => {
    const [invoices, setInvoices] = useState([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('ALL');
    const [searchQuery, setSearchQuery] = useState('');
    const { token } = useContext(AuthContext);

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => {
        const fetchInvoices = async () => {
            try {
                const res = await axios.get('/api/invoices/', hdrs);
                setInvoices(res.data);
            } catch (err) { console.error(err); }
            finally { setLoading(false); }
        };
        if (token) fetchInvoices();
    }, [token]);

    const handleCancel = async (id) => {
        if (!confirm('Cancel this invoice? This cannot be undone.')) return;
        try {
            const res = await axios.post(`/api/invoices/${id}/cancel/`, {}, hdrs);
            setInvoices(invoices.map(inv => inv.id === id ? res.data : inv));
        } catch (e) { alert('Failed to cancel invoice'); }
    };

    const handleIssue = async (id) => {
        try {
            const res = await axios.post(`/api/invoices/${id}/issue/`, {}, hdrs);
            setInvoices(invoices.map(inv => inv.id === id ? res.data : inv));
        } catch (e) { alert('Failed to issue invoice'); }
    };

    const handleDownloadPDF = (inv) => {
        // Generate a printable invoice view
        const company = 'Your Company'; // Will be fetched from settings in production
        const w = window.open('', '_blank');
        const items = inv.items || [];
        const itemRows = items.map(it => `
            <tr>
                <td style="padding:8px;border-bottom:1px solid #eee">${it.product_name || 'Item'}</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${it.product_hsn || '-'}</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${it.quantity}</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:right">₹${parseFloat(it.unit_price).toFixed(2)}</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${it.gst_rate}%</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:right">₹${parseFloat(it.total).toFixed(2)}</td>
            </tr>
        `).join('');

        w.document.write(`
            <!DOCTYPE html><html><head><title>Invoice ${inv.invoice_number}</title>
            <style>
                body{font-family:'Segoe UI',sans-serif;margin:0;padding:40px;color:#1a1a1a;background:#fff}
                .header{display:flex;justify-content:space-between;border-bottom:3px solid #4f46e5;padding-bottom:20px;margin-bottom:30px}
                .inv-title{font-size:28px;font-weight:800;color:#4f46e5}
                table{width:100%;border-collapse:collapse;margin:20px 0}
                th{background:#f8fafc;padding:10px 8px;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#6b7280;border-bottom:2px solid #e5e7eb}
                .totals{text-align:right;margin-top:20px}
                .totals td{padding:6px 12px}
                .grand-total{font-size:18px;font-weight:800;color:#4f46e5;border-top:2px solid #4f46e5;padding-top:10px}
                .footer{margin-top:40px;text-align:center;color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;padding-top:20px}
                @media print{body{padding:20px}button{display:none !important}}
            </style></head><body>
            <div class="header">
                <div><div class="inv-title">${inv.invoice_type === 'PROFORMA' ? 'PROFORMA INVOICE' : 'TAX INVOICE'}</div>
                <div style="color:#6b7280;margin-top:4px">${inv.invoice_number}</div></div>
                <div style="text-align:right"><div style="font-size:12px;color:#6b7280">Date: ${new Date(inv.date).toLocaleDateString('en-IN')}</div>
                ${inv.due_date ? `<div style="font-size:12px;color:#6b7280">Due: ${new Date(inv.due_date).toLocaleDateString('en-IN')}</div>` : ''}
                <div style="margin-top:8px;display:inline-block;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:700;background:${inv.status === 'PAID' ? '#ecfdf5;color:#059669' : inv.status === 'CANCELLED' ? '#fef2f2;color:#dc2626' : '#eff6ff;color:#2563eb'}">${inv.status}</div></div>
            </div>
            <div style="display:flex;gap:40px;margin-bottom:30px">
                <div style="flex:1"><div style="font-size:11px;color:#6b7280;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px">Bill To</div>
                <div style="font-weight:700;font-size:16px">${inv.customer_details?.name || 'Customer'}</div>
                <div style="color:#6b7280;font-size:13px;margin-top:4px">${inv.customer_details?.address || ''}</div>
                <div style="color:#6b7280;font-size:13px">GSTIN: ${inv.customer_details?.gstin || 'N/A'}</div>
                <div style="color:#6b7280;font-size:13px">State: ${inv.customer_details?.state_code || ''}</div></div>
            </div>
            <table><thead><tr><th>Item</th><th style="text-align:center">HSN/SAC</th><th style="text-align:center">Qty</th><th style="text-align:right">Rate</th><th style="text-align:center">GST %</th><th style="text-align:right">Total</th></tr></thead>
            <tbody>${itemRows || '<tr><td colspan="6" style="padding:20px;text-align:center;color:#9ca3af">No items</td></tr>'}</tbody></table>
            <table class="totals" style="width:300px;margin-left:auto"><tbody>
                <tr><td style="color:#6b7280">Subtotal</td><td style="font-weight:600">₹${parseFloat(inv.subtotal).toFixed(2)}</td></tr>
                <tr><td style="color:#6b7280">CGST</td><td>₹${parseFloat(inv.cgst_total).toFixed(2)}</td></tr>
                <tr><td style="color:#6b7280">SGST</td><td>₹${parseFloat(inv.sgst_total).toFixed(2)}</td></tr>
                <tr><td style="color:#6b7280">IGST</td><td>₹${parseFloat(inv.igst_total).toFixed(2)}</td></tr>
                <tr><td class="grand-total">Grand Total</td><td class="grand-total">₹${parseFloat(inv.total).toFixed(2)}</td></tr>
                <tr><td style="color:#6b7280">Amount Paid</td><td style="color:#059669;font-weight:600">₹${parseFloat(inv.amount_paid).toFixed(2)}</td></tr>
                <tr><td style="color:#6b7280">Balance Due</td><td style="color:#dc2626;font-weight:700">₹${(parseFloat(inv.total) - parseFloat(inv.amount_paid)).toFixed(2)}</td></tr>
            </tbody></table>
            <div class="footer">This is a computer generated invoice. | GST Billing System<br>
            <button onclick="window.print()" style="margin-top:16px;padding:10px 32px;background:#4f46e5;color:white;border:none;border-radius:8px;font-weight:700;cursor:pointer;font-size:14px">Print / Save as PDF</button></div>
            </body></html>
        `);
        w.document.close();
    };

    const getStatusTheme = (status) => {
        switch (status) {
            case 'PAID': return 'bg-emerald-50 text-emerald-600 border border-emerald-100';
            case 'PARTIAL': return 'bg-amber-50 text-amber-600 border border-amber-100';
            case 'DRAFT': return 'bg-gray-100 text-gray-600 border border-gray-200';
            case 'ISSUED': return 'bg-blue-50 text-blue-600 border border-blue-100';
            case 'CANCELLED': return 'bg-rose-50 text-rose-600 border border-rose-100';
            default: return 'bg-gray-50 text-gray-600 border border-gray-100';
        }
    };

    const filtered = invoices.filter(inv => {
        const matchStatus = statusFilter === 'ALL' || inv.status === statusFilter;
        const q = searchQuery.toLowerCase();
        const matchSearch = inv.invoice_number.toLowerCase().includes(q) || (inv.customer_details?.name || '').toLowerCase().includes(q);
        return matchStatus && matchSearch;
    });

    const statusCounts = { ALL: invoices.length, DRAFT: 0, ISSUED: 0, PAID: 0, PARTIAL: 0, CANCELLED: 0 };
    invoices.forEach(inv => { if (statusCounts[inv.status] !== undefined) statusCounts[inv.status]++; });

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Invoices</h2>
                    <p className="text-gray-500 mt-1 font-medium">Manage tax invoices, proforma invoices and track payments.</p>
                </div>
                <div className="flex gap-3">
                    <Link to="/invoices/create" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                        <Plus size={18} /> Create Invoice
                    </Link>
                </div>
            </div>

            {/* Filters */}
            <div className="flex flex-wrap gap-3 items-center">
                <div className="relative flex-1 max-w-xs">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input type="text" value={searchQuery} onChange={e => setSearchQuery(e.target.value)} placeholder="Search invoices..."
                        className="w-full bg-white border border-gray-200 text-sm rounded-xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all font-medium shadow-sm" />
                </div>
                <div className="flex gap-1.5">
                    {['ALL', 'DRAFT', 'ISSUED', 'PARTIAL', 'PAID', 'CANCELLED'].map(s => (
                        <button key={s} onClick={() => setStatusFilter(s)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition-all ${statusFilter === s ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-gray-500 border border-gray-200 hover:bg-gray-50'
                                }`}>
                            {s} {statusCounts[s] > 0 ? `(${statusCounts[s]})` : ''}
                        </button>
                    ))}
                </div>
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="overflow-x-auto">
                    {loading ? (
                        <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
                    ) : filtered.length === 0 ? (
                        <div className="p-16 text-center">
                            <FileText size={48} className="mx-auto text-gray-300 mb-4" />
                            <h3 className="text-lg font-bold text-gray-900 mb-2">{searchQuery || statusFilter !== 'ALL' ? 'No invoices match' : 'No invoices created'}</h3>
                            <p className="text-gray-500 max-w-sm mx-auto">{searchQuery || statusFilter !== 'ALL' ? 'Try different filters.' : 'Create your first invoice to bill customers.'}</p>
                        </div>
                    ) : (
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/80 border-b border-gray-100 uppercase text-xs font-semibold tracking-wider text-gray-500">
                                    <th className="p-4 pl-6">Invoice</th>
                                    <th className="p-4">Customer</th>
                                    <th className="p-4">Date</th>
                                    <th className="p-4">Amount</th>
                                    <th className="p-4">Paid</th>
                                    <th className="p-4">Status</th>
                                    <th className="p-4 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {filtered.map((inv) => {
                                    const balance = parseFloat(inv.total) - parseFloat(inv.amount_paid);
                                    return (
                                        <tr key={inv.id} className="hover:bg-gray-50/50 transition-colors group">
                                            <td className="p-4 pl-6">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 rounded-xl bg-indigo-50/80 flex items-center justify-center text-indigo-600 shadow-inner">
                                                        <FileText size={18} />
                                                    </div>
                                                    <div>
                                                        <span className="font-semibold text-gray-900">{inv.invoice_number}</span>
                                                        {inv.invoice_type === 'PROFORMA' && <span className="ml-2 text-[9px] bg-purple-100 text-purple-600 px-1.5 py-0.5 rounded-full font-bold uppercase">Proforma</span>}
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <p className="font-medium text-gray-900">{inv.customer_details?.name || 'Unknown'}</p>
                                                <p className="text-xs text-gray-500">GSTIN: {inv.customer_details?.gstin || 'N/A'}</p>
                                            </td>
                                            <td className="p-4 font-medium text-gray-600">{new Date(inv.date).toLocaleDateString('en-IN')}</td>
                                            <td className="p-4 font-bold text-gray-900">₹{parseFloat(inv.total).toFixed(2)}</td>
                                            <td className="p-4">
                                                <span className={`font-bold ${balance > 0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                                                    ₹{parseFloat(inv.amount_paid).toFixed(2)}
                                                </span>
                                            </td>
                                            <td className="p-4">
                                                <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${getStatusTheme(inv.status)}`}>
                                                    {inv.status}
                                                </span>
                                            </td>
                                            <td className="p-4">
                                                <div className="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <button onClick={() => handleDownloadPDF(inv)} className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors" title="View / Print PDF">
                                                        <Download size={16} />
                                                    </button>
                                                    {inv.status === 'DRAFT' && (
                                                        <button onClick={() => handleIssue(inv.id)} className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Issue Invoice">
                                                            <Send size={16} />
                                                        </button>
                                                    )}
                                                    {(inv.status === 'DRAFT' || inv.status === 'ISSUED') && (
                                                        <button onClick={() => handleCancel(inv.id)} className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors" title="Cancel Invoice">
                                                            <XCircle size={16} />
                                                        </button>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>

            {!loading && filtered.length > 0 && (
                <p className="text-sm text-gray-500 text-center font-medium">Showing {filtered.length} of {invoices.length} invoices</p>
            )}
        </div>
    );
};

export default Invoices;
