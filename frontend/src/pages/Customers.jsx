import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Users, UserPlus, Edit2, Trash2, X, Phone, Mail, MapPin, CheckCircle, XCircle } from 'lucide-react';

const Customers = () => {
    const [customers, setCustomers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [gstinValid, setGstinValid] = useState(null);
    const { token } = useContext(AuthContext);
    const [form, setForm] = useState({ name: '', email: '', phone: '', address: '', shipping_address: '', gstin: '', state_code: '29' });

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchCustomers(); }, []);

    const fetchCustomers = async () => {
        try {
            const res = await axios.get('/api/customers/', hdrs);
            setCustomers(res.data);
        } catch (err) { console.error(err); }
        finally { setLoading(false); }
    };

    const resetForm = () => { setForm({ name: '', email: '', phone: '', address: '', shipping_address: '', gstin: '', state_code: '29' }); setShowForm(false); setEditingId(null); setGstinValid(null); };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingId) {
                await axios.put(`/api/customers/${editingId}/`, form, hdrs);
            } else {
                await axios.post('/api/customers/', form, hdrs);
            }
            fetchCustomers();
            resetForm();
        } catch (e) { alert('Failed to save customer'); }
    };

    const handleEdit = (c) => {
        setForm({ name: c.name, email: c.email || '', phone: c.phone, address: c.address, shipping_address: c.shipping_address || '', gstin: c.gstin || '', state_code: c.state_code });
        setEditingId(c.id);
        setShowForm(true);
    };

    const handleDelete = async (id) => {
        if (!confirm('Delete this customer?')) return;
        try {
            await axios.delete(`/api/customers/${id}/`, hdrs);
            setCustomers(customers.filter(c => c.id !== id));
        } catch (e) { alert('Failed to delete'); }
    };

    const validateGstin = async () => {
        if (!form.gstin) return;
        try {
            const res = await axios.post('/api/customers/validate_gstin/', { gstin: form.gstin }, hdrs);
            setGstinValid(res.data.is_valid);
        } catch (e) { setGstinValid(false); }
    };

    const fmt = (v) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(v || 0);

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Customers</h2>
                    <p className="text-gray-500 mt-1 font-medium">Manage your client base and GST information.</p>
                </div>
                <button onClick={() => { resetForm(); setShowForm(true); }} className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                    <UserPlus size={18} /> Add Customer
                </button>
            </div>

            {showForm && (
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-bold text-gray-900">{editingId ? 'Edit Customer' : 'Add New Customer'}</h3>
                        <button onClick={resetForm} className="p-2 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
                    </div>
                    <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Customer Name *</label>
                            <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">GSTIN</label>
                            <div className="flex gap-2">
                                <input value={form.gstin} onChange={e => { setForm({ ...form, gstin: e.target.value }); setGstinValid(null); }} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" placeholder="22AAAAA0000A1Z5" />
                                <button type="button" onClick={validateGstin} className="px-3 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200 text-sm shrink-0">Validate</button>
                            </div>
                            {gstinValid !== null && (
                                <div className={`flex items-center gap-1 mt-1 text-xs font-semibold ${gstinValid ? 'text-emerald-600' : 'text-rose-600'}`}>
                                    {gstinValid ? <><CheckCircle size={12} /> Valid GSTIN format</> : <><XCircle size={12} /> Invalid GSTIN format</>}
                                </div>
                            )}
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Phone *</label>
                            <input required value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Email</label>
                            <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">State Code *</label>
                            <input required value={form.state_code} onChange={e => setForm({ ...form, state_code: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" maxLength="2" />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Billing Address *</label>
                            <textarea required value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} rows={2} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none resize-none" />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Shipping Address</label>
                            <textarea value={form.shipping_address} onChange={e => setForm({ ...form, shipping_address: e.target.value })} rows={2} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none resize-none" placeholder="Same as billing if left blank" />
                        </div>
                        <div className="md:col-span-2 flex gap-3 justify-end">
                            <button type="button" onClick={resetForm} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200">Cancel</button>
                            <button type="submit" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20">{editingId ? 'Update' : 'Save'} Customer</button>
                        </div>
                    </form>
                </div>
            )}

            {loading ? (
                <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
            ) : customers.length === 0 ? (
                <div className="bg-white rounded-3xl p-12 text-center shadow-sm border border-gray-100">
                    <Users size={48} className="mx-auto text-gray-300 mb-4" />
                    <h3 className="text-lg font-bold text-gray-900 mb-2">No customers found</h3>
                    <p className="text-gray-500 max-w-sm mx-auto">Get started by adding your first customer to the system to begin invoicing.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {customers.map((c) => (
                        <div key={c.id} className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-all group relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/5 rounded-bl-full group-hover:scale-110 transition-transform duration-500"></div>
                            <div className="flex items-start justify-between relative z-10">
                                <div className="flex gap-4 items-center">
                                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center border-2 border-white shadow-sm font-bold text-xl text-indigo-700 uppercase">
                                        {c.name.substring(0, 2)}
                                    </div>
                                    <div>
                                        <h3 className="font-bold text-gray-900 text-lg">{c.name}</h3>
                                        <span className="text-xs font-semibold tracking-wider text-gray-500 uppercase bg-gray-100 px-2 py-0.5 rounded-full inline-block mt-1">State: {c.state_code}</span>
                                    </div>
                                </div>
                                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <button onClick={() => handleEdit(c)} className="p-1.5 hover:bg-indigo-50 text-gray-400 hover:text-indigo-600 rounded-lg"><Edit2 size={16} /></button>
                                    <button onClick={() => handleDelete(c.id)} className="p-1.5 hover:bg-rose-50 text-gray-400 hover:text-rose-600 rounded-lg"><Trash2 size={16} /></button>
                                </div>
                            </div>
                            <div className="mt-6 space-y-3 relative z-10">
                                <div className="flex justify-between text-sm">
                                    <span className="text-gray-500 font-medium">GSTIN</span>
                                    <span className="font-semibold text-gray-900">{c.gstin || 'N/A'}</span>
                                </div>
                                <div className="flex justify-between text-sm">
                                    <span className="text-gray-500 font-medium">Outstanding</span>
                                    <span className={`font-bold ${c.total_outstanding > 0 ? 'text-rose-600' : 'text-emerald-600'}`}>{fmt(c.total_outstanding)}</span>
                                </div>
                            </div>
                            <div className="mt-6 pt-5 border-t border-gray-100 flex justify-between items-center relative z-10">
                                <span className="text-sm font-medium text-gray-500 truncate">{c.email || 'No email'}</span>
                                <span className="text-sm font-medium text-gray-500"><Phone size={12} className="inline mr-1" />{c.phone}</span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Customers;
