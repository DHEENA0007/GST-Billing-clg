import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Store, Plus, Edit2, Trash2, X, Phone, Mail, MapPin } from 'lucide-react';

const Vendors = () => {
    const { token } = useContext(AuthContext);
    const [vendors, setVendors] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [form, setForm] = useState({ name: '', email: '', phone: '', address: '', gstin: '', state_code: '29' });

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchVendors(); }, []);

    const fetchVendors = async () => {
        try {
            const res = await axios.get('/api/vendors/', hdrs);
            setVendors(res.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const resetForm = () => { setForm({ name: '', email: '', phone: '', address: '', gstin: '', state_code: '29' }); setShowForm(false); setEditingId(null); };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingId) {
                await axios.put(`/api/vendors/${editingId}/`, form, hdrs);
            } else {
                await axios.post('/api/vendors/', form, hdrs);
            }
            fetchVendors();
            resetForm();
        } catch (e) { alert('Failed to save vendor'); }
    };

    const handleEdit = (v) => {
        setForm({ name: v.name, email: v.email || '', phone: v.phone, address: v.address, gstin: v.gstin || '', state_code: v.state_code });
        setEditingId(v.id);
        setShowForm(true);
    };

    const handleDelete = async (id) => {
        if (!confirm('Delete this vendor?')) return;
        try {
            await axios.delete(`/api/vendors/${id}/`, hdrs);
            setVendors(vendors.filter(v => v.id !== id));
        } catch (e) { alert('Failed to delete'); }
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <Store className="text-indigo-600" size={28} /> Vendors & Suppliers
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Manage your supplier base and purchase details.</p>
                </div>
                <button onClick={() => { resetForm(); setShowForm(true); }} className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                    <Plus size={18} /> Add Vendor
                </button>
            </div>

            {showForm && (
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-bold text-gray-900">{editingId ? 'Edit Vendor' : 'Add New Vendor'}</h3>
                        <button onClick={resetForm} className="p-2 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
                    </div>
                    <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Vendor Name *</label>
                            <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">GSTIN</label>
                            <input value={form.gstin} onChange={e => setForm({ ...form, gstin: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" placeholder="22AAAAA0000A1Z5" />
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
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Address *</label>
                            <textarea required value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} rows={2} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none resize-none" />
                        </div>
                        <div className="md:col-span-2 flex gap-3 justify-end">
                            <button type="button" onClick={resetForm} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200">Cancel</button>
                            <button type="submit" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20">{editingId ? 'Update' : 'Save'} Vendor</button>
                        </div>
                    </form>
                </div>
            )}

            {loading ? (
                <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
            ) : vendors.length === 0 ? (
                <div className="bg-white rounded-3xl p-12 text-center shadow-sm border border-gray-100">
                    <Store size={48} className="mx-auto text-gray-300 mb-4" />
                    <h3 className="text-lg font-bold text-gray-900 mb-2">No vendors added</h3>
                    <p className="text-gray-500 max-w-sm mx-auto">Add your first vendor/supplier to start tracking purchases.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {vendors.map(v => (
                        <div key={v.id} className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-all group relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/5 rounded-bl-full group-hover:scale-110 transition-transform duration-500"></div>
                            <div className="flex items-start justify-between relative z-10">
                                <div className="flex gap-4 items-center">
                                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-purple-100 to-indigo-100 flex items-center justify-center border-2 border-white shadow-sm font-bold text-xl text-purple-700 uppercase">
                                        {v.name.substring(0, 2)}
                                    </div>
                                    <div>
                                        <h3 className="font-bold text-gray-900 text-lg">{v.name}</h3>
                                        <span className="text-xs font-semibold tracking-wider text-gray-500 uppercase bg-gray-100 px-2 py-0.5 rounded-full">{v.gstin || 'No GSTIN'}</span>
                                    </div>
                                </div>
                                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <button onClick={() => handleEdit(v)} className="p-1.5 hover:bg-indigo-50 text-gray-400 hover:text-indigo-600 rounded-lg"><Edit2 size={16} /></button>
                                    <button onClick={() => handleDelete(v.id)} className="p-1.5 hover:bg-rose-50 text-gray-400 hover:text-rose-600 rounded-lg"><Trash2 size={16} /></button>
                                </div>
                            </div>
                            <div className="mt-5 space-y-2 relative z-10 text-sm">
                                <div className="flex items-center gap-2 text-gray-600"><Phone size={14} className="text-gray-400" /> {v.phone}</div>
                                <div className="flex items-center gap-2 text-gray-600"><Mail size={14} className="text-gray-400" /> {v.email || 'N/A'}</div>
                                <div className="flex items-center gap-2 text-gray-600"><MapPin size={14} className="text-gray-400" /> State: {v.state_code}</div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Vendors;
