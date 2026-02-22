import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { CreditCard, Plus, X, FileText, ArrowUpDown } from 'lucide-react';

const Payments = () => {
    const { token } = useContext(AuthContext);
    const [payments, setPayments] = useState([]);
    const [invoices, setInvoices] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [form, setForm] = useState({ invoice: '', amount: '', mode: 'BANK', reference_number: '', notes: '', date: new Date().toISOString().split('T')[0] });

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };
    const fmt = (v) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(v || 0);

    useEffect(() => { fetchData(); }, []);

    const fetchData = async () => {
        try {
            const [pRes, iRes] = await Promise.all([
                axios.get('/api/payments/', hdrs),
                axios.get('/api/invoices/', hdrs)
            ]);
            setPayments(pRes.data);
            setInvoices(iRes.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await axios.post('/api/payments/', form, hdrs);
            fetchData();
            setShowForm(false);
            setForm({ invoice: '', amount: '', mode: 'BANK', reference_number: '', notes: '', date: new Date().toISOString().split('T')[0] });
        } catch (e) { alert('Failed to record payment'); }
    };

    const modeColors = {
        CASH: 'bg-emerald-50 text-emerald-600 border-emerald-100',
        BANK: 'bg-blue-50 text-blue-600 border-blue-100',
        UPI: 'bg-purple-50 text-purple-600 border-purple-100',
        CARD: 'bg-amber-50 text-amber-600 border-amber-100',
        CHEQUE: 'bg-gray-100 text-gray-600 border-gray-200'
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <CreditCard className="text-indigo-600" size={28} /> Payment Management
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Record and track all payments received.</p>
                </div>
                <button onClick={() => setShowForm(true)} className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                    <Plus size={18} /> Record Payment
                </button>
            </div>

            {showForm && (
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-bold text-gray-900">Record New Payment</h3>
                        <button onClick={() => setShowForm(false)} className="p-2 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
                    </div>
                    <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Invoice *</label>
                            <select required value={form.invoice} onChange={e => setForm({ ...form, invoice: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none">
                                <option value="">Select Invoice</option>
                                {invoices.filter(i => i.status !== 'PAID' && i.status !== 'CANCELLED').map(i => (
                                    <option key={i.id} value={i.id}>{i.invoice_number} - {i.customer_details?.name} ({fmt(i.total - i.amount_paid)} due)</option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Amount *</label>
                            <input required type="number" step="0.01" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Payment Mode *</label>
                            <select value={form.mode} onChange={e => setForm({ ...form, mode: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none">
                                <option value="CASH">Cash</option>
                                <option value="BANK">Bank Transfer</option>
                                <option value="UPI">UPI</option>
                                <option value="CARD">Card</option>
                                <option value="CHEQUE">Cheque</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Date *</label>
                            <input required type="date" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Reference No.</label>
                            <input value={form.reference_number} onChange={e => setForm({ ...form, reference_number: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" placeholder="UTR / Cheque No" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Notes</label>
                            <input value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div className="md:col-span-2 flex gap-3 justify-end">
                            <button type="button" onClick={() => setShowForm(false)} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200">Cancel</button>
                            <button type="submit" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20">Record Payment</button>
                        </div>
                    </form>
                </div>
            )}

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
                ) : payments.length === 0 ? (
                    <div className="p-16 text-center">
                        <CreditCard size={48} className="mx-auto text-gray-300 mb-4" />
                        <h3 className="text-lg font-bold text-gray-900 mb-2">No payments recorded</h3>
                        <p className="text-gray-500">Start recording payments against invoices.</p>
                    </div>
                ) : (
                    <table className="w-full text-left">
                        <thead><tr className="bg-gray-50/80 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                            <th className="p-4 pl-6">Date</th><th className="p-4">Invoice</th><th className="p-4">Amount</th><th className="p-4">Mode</th><th className="p-4">Reference</th><th className="p-4">Notes</th>
                        </tr></thead>
                        <tbody className="divide-y divide-gray-50">
                            {payments.map(p => (
                                <tr key={p.id} className="hover:bg-gray-50/50 transition-colors">
                                    <td className="p-4 pl-6 font-medium text-gray-600">{new Date(p.date).toLocaleDateString()}</td>
                                    <td className="p-4 font-semibold text-gray-900">{p.invoice_number || 'N/A'}</td>
                                    <td className="p-4 font-bold text-emerald-600">{fmt(p.amount)}</td>
                                    <td className="p-4"><span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider border ${modeColors[p.mode]}`}>{p.mode}</span></td>
                                    <td className="p-4 text-gray-600">{p.reference_number || '-'}</td>
                                    <td className="p-4 text-gray-500 text-sm">{p.notes || '-'}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
};

export default Payments;
