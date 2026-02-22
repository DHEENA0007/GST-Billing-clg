import React, { useState, useEffect, useContext } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Plus, Download, Filter, MoreVertical, FileText } from 'lucide-react';

const Invoices = () => {
    const [invoices, setInvoices] = useState([]);
    const [loading, setLoading] = useState(true);
    const { token } = useContext(AuthContext);

    useEffect(() => {
        const fetchInvoices = async () => {
            try {
                const res = await axios.get('/api/invoices/', {
                    headers: { Authorization: `Bearer ${token}` }
                });
                setInvoices(res.data);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        if (token) fetchInvoices();
    }, [token]);

    const getStatusTheme = (status) => {
        switch (status) {
            case 'PAID': return 'bg-emerald-50 text-emerald-600 border border-emerald-100';
            case 'PARTIAL': return 'bg-amber-50 text-amber-600 border border-amber-100';
            case 'DRAFT': return 'bg-gray-100 text-gray-600 border border-gray-200';
            case 'ISSUED': return 'bg-blue-50 text-blue-600 border border-blue-100';
            default: return 'bg-gray-50 text-gray-600 border border-gray-100';
        }
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Invoices</h2>
                    <p className="text-gray-500 mt-1 font-medium">Manage your tax invoices, credit notes and delivery challans.</p>
                </div>
                <div className="flex gap-3">
                    <button className="px-4 py-2 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl hover:bg-gray-50 transition-all shadow-sm flex items-center gap-2">
                        <Filter size={18} /> Filter
                    </button>
                    <Link to="/invoices/create" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                        <Plus size={18} /> Create Invoice
                    </Link>
                </div>
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="overflow-x-auto">
                    {loading ? (
                        <div className="py-20 flex justify-center">
                            <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div>
                        </div>
                    ) : invoices.length === 0 ? (
                        <div className="p-16 text-center">
                            <FileText size={48} className="mx-auto text-gray-300 mb-4" />
                            <h3 className="text-lg font-bold text-gray-900 mb-2">No invoices created</h3>
                            <p className="text-gray-500 max-w-sm mx-auto">Create your first invoice to bill customers.</p>
                        </div>
                    ) : (
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/80 border-b border-gray-100 uppercase text-xs font-semibold tracking-wider text-gray-500">
                                    <th className="p-4 pl-6">Invoice Number</th>
                                    <th className="p-4">Customer</th>
                                    <th className="p-4 relative">
                                        <div className="flex items-center gap-2">Date <span className="text-[10px] w-4 h-4 rounded-full bg-gray-200 flex items-center justify-center">↓</span></div>
                                    </th>
                                    <th className="p-4">Amount</th>
                                    <th className="p-4">Status</th>
                                    <th className="p-4 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {invoices.map((inv) => (
                                    <tr key={inv.id} className="hover:bg-gray-50/50 transition-colors group">
                                        <td className="p-4 pl-6">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-xl bg-indigo-50/80 flex items-center justify-center text-indigo-600 shadow-inner">
                                                    <FileText size={18} />
                                                </div>
                                                <span className="font-semibold text-gray-900">{inv.invoice_number}</span>
                                            </div>
                                        </td>
                                        <td className="p-4">
                                            <p className="font-medium text-gray-900">{inv.customer_details?.name || 'Unknown'}</p>
                                            <p className="text-xs text-gray-500">GSTIN: {inv.customer_details?.gstin || 'N/A'}</p>
                                        </td>
                                        <td className="p-4 font-medium text-gray-600">{new Date(inv.date).toLocaleDateString()}</td>
                                        <td className="p-4">
                                            <p className="font-bold text-gray-900">₹{parseFloat(inv.total).toFixed(2)}</p>
                                            <p className="text-xs text-gray-400">Total + GST</p>
                                        </td>
                                        <td className="p-4">
                                            <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${getStatusTheme(inv.status)}`}>
                                                {inv.status}
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            <div className="flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                                                    <Download size={18} />
                                                </button>
                                                <button className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors">
                                                    <MoreVertical size={18} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Invoices;
