import React, { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { FileText, Plus, X, ArrowDownCircle, ArrowUpCircle, ExternalLink, Trash2 } from 'lucide-react';

const CreditDebitNotes = () => {
    const { token } = useContext(AuthContext);
    const navigate = useNavigate();
    const [notes, setNotes] = useState([]);
    const [invoices, setInvoices] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [form, setForm] = useState({ note_type: 'CREDIT', note_number: '', invoice: '', date: new Date().toISOString().split('T')[0], reason: '', amount: '', gst_adjustment: '0' });

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchData(); }, []);

    const fetchData = async () => {
        try {
            const [notesRes, invRes] = await Promise.all([
                axios.get('/api/credit-debit-notes/', hdrs),
                axios.get('/api/invoices/', hdrs)
            ]);
            setNotes(notesRes.data);
            setInvoices(invRes.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const resetForm = () => {
        setForm({ note_type: 'CREDIT', note_number: `CN-${Date.now().toString().slice(-6)}`, invoice: '', date: new Date().toISOString().split('T')[0], reason: '', amount: '', gst_adjustment: '0' });
        setShowForm(false);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const res = await axios.post('/api/credit-debit-notes/', form, hdrs);
            setNotes([res.data, ...notes]);
            resetForm();
        } catch (e) { alert(e.response?.data?.detail || 'Failed to create note'); }
    };

    const handleDelete = async (id) => {
        if (!confirm('Delete this note?')) return;
        try {
            await axios.delete(`/api/credit-debit-notes/${id}/`, hdrs);
            setNotes(notes.filter(n => n.id !== id));
        } catch (e) { alert('Failed to delete'); }
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Credit / Debit Notes</h2>
                    <p className="text-gray-500 mt-1 font-medium">Issue credit or debit notes linked to original invoices.</p>
                </div>
                <button onClick={() => { resetForm(); setShowForm(true); }} className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                    <Plus size={18} /> Issue Note
                </button>
            </div>

            {showForm && (
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-bold text-gray-900">Issue New Note</h3>
                        <button onClick={resetForm} className="p-2 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
                    </div>
                    <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Note Type *</label>
                            <select value={form.note_type} onChange={e => setForm({ ...form, note_type: e.target.value, note_number: `${e.target.value === 'CREDIT' ? 'CN' : 'DN'}-${Date.now().toString().slice(-6)}` })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium bg-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600">
                                <option value="CREDIT">Credit Note (Refund to Customer)</option>
                                <option value="DEBIT">Debit Note (Charge to Customer)</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Note Number *</label>
                            <input required value={form.note_number} onChange={e => setForm({ ...form, note_number: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Linked Invoice *</label>
                            <select required value={form.invoice} onChange={e => setForm({ ...form, invoice: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium bg-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600">
                                <option value="">-- Select Invoice --</option>
                                {invoices.map(i => <option key={i.id} value={i.id}>{i.invoice_number} — {i.customer_details?.name} (₹{i.total})</option>)}
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Date</label>
                            <input type="date" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Amount (₹) *</label>
                            <input required type="number" step="0.01" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">GST Adjustment (₹)</label>
                            <input type="number" step="0.01" value={form.gst_adjustment} onChange={e => setForm({ ...form, gst_adjustment: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600" />
                        </div>
                        <div className="md:col-span-3">
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Reason *</label>
                            <textarea required rows="2" value={form.reason} onChange={e => setForm({ ...form, reason: e.target.value })}
                                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl outline-none font-medium resize-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600"
                                placeholder="Reason for issuing this note..."></textarea>
                        </div>
                        <div className="md:col-span-3 flex gap-3 justify-end">
                            <button type="button" onClick={resetForm} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200">Cancel</button>
                            <button type="submit" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20">Issue Note</button>
                        </div>
                    </form>
                </div>
            )}

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
                ) : notes.length === 0 ? (
                    <div className="p-16 text-center">
                        <FileText size={48} className="mx-auto text-gray-300 mb-4" />
                        <h3 className="text-lg font-bold text-gray-900 mb-2">No notes issued</h3>
                        <p className="text-gray-500">Issue a credit or debit note to adjust invoices.</p>
                    </div>
                ) : (
                    <table className="w-full text-left border-collapse">
                        <thead><tr className="bg-gray-50/80 border-b border-gray-100 uppercase text-xs font-semibold tracking-wider text-gray-500">
                            <th className="p-4 pl-6">Note</th>
                            <th className="p-4">Type</th>
                            <th className="p-4">Linked Invoice</th>
                            <th className="p-4">Date</th>
                            <th className="p-4">Amount</th>
                            <th className="p-4">GST Adj.</th>
                            <th className="p-4">Reason</th>
                        </tr></thead>
                        <tbody className="divide-y divide-gray-50">
                            {notes.map(n => (
                                <tr key={n.id} className="hover:bg-gray-50/50 transition-colors">
                                    <td className="p-4 pl-6 font-bold text-gray-900">{n.note_number}</td>
                                    <td className="p-4">
                                        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase ${n.note_type === 'CREDIT' ? 'bg-emerald-50 text-emerald-600 border border-emerald-100' : 'bg-rose-50 text-rose-600 border border-rose-100'
                                            }`}>
                                            {n.note_type === 'CREDIT' ? <ArrowDownCircle size={12} /> : <ArrowUpCircle size={12} />}
                                            {n.note_type}
                                        </span>
                                    </td>
                                    <td className="p-4">
                                        <button onClick={() => navigate('/invoices')} className="text-indigo-600 font-medium flex items-center gap-1.5 hover:text-indigo-800 hover:underline transition-colors cursor-pointer bg-transparent border-none p-0">
                                            <ExternalLink size={13} /> {n.invoice_number || `INV #${n.invoice}`}
                                        </button>
                                    </td>
                                    <td className="p-4 text-gray-600 font-medium">{new Date(n.date).toLocaleDateString('en-IN')}</td>
                                    <td className="p-4 font-bold text-gray-900">₹{parseFloat(n.amount).toFixed(2)}</td>
                                    <td className="p-4 text-gray-600">₹{parseFloat(n.gst_adjustment).toFixed(2)}</td>
                                    <td className="p-4 text-sm text-gray-600 max-w-xs truncate">{n.reason}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
};

export default CreditDebitNotes;
