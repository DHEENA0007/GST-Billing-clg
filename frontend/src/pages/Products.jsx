import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { PackagePlus, Settings, Database, Package, Edit2, Trash2, X, AlertTriangle } from 'lucide-react';

const Products = () => {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const { token } = useContext(AuthContext);
    const [form, setForm] = useState({ name: '', description: '', hsn_sac: '', price: '', gst_rate: '18', unit: 'PCS', stock: '0', low_stock_threshold: '10' });

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchProducts(); }, []);

    const fetchProducts = async () => {
        try {
            const res = await axios.get('/api/products/', hdrs);
            setProducts(res.data);
        } catch (err) { console.error(err); }
        finally { setLoading(false); }
    };

    const resetForm = () => { setForm({ name: '', description: '', hsn_sac: '', price: '', gst_rate: '18', unit: 'PCS', stock: '0', low_stock_threshold: '10' }); setShowForm(false); setEditingId(null); };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingId) {
                await axios.put(`/api/products/${editingId}/`, form, hdrs);
            } else {
                await axios.post('/api/products/', form, hdrs);
            }
            fetchProducts();
            resetForm();
        } catch (e) { alert('Failed to save product'); }
    };

    const handleEdit = (p) => {
        setForm({ name: p.name, description: p.description || '', hsn_sac: p.hsn_sac, price: p.price, gst_rate: p.gst_rate, unit: p.unit, stock: p.stock, low_stock_threshold: p.low_stock_threshold });
        setEditingId(p.id);
        setShowForm(true);
    };

    const handleDelete = async (id) => {
        if (!confirm('Delete this product?')) return;
        try {
            await axios.delete(`/api/products/${id}/`, hdrs);
            setProducts(products.filter(p => p.id !== id));
        } catch (e) { alert('Failed to delete'); }
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">Products & Services</h2>
                    <p className="text-gray-500 mt-1 font-medium">Manage inventory, HSN codes and GST rates.</p>
                </div>
                <button onClick={() => { resetForm(); setShowForm(true); }} className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5">
                    <PackagePlus size={18} /> Add Item
                </button>
            </div>

            {showForm && (
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-bold text-gray-900">{editingId ? 'Edit Product' : 'Add New Product'}</h3>
                        <button onClick={resetForm} className="p-2 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
                    </div>
                    <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Product Name *</label>
                            <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">HSN/SAC Code *</label>
                            <input required value={form.hsn_sac} onChange={e => setForm({ ...form, hsn_sac: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">GST Rate (%) *</label>
                            <select value={form.gst_rate} onChange={e => setForm({ ...form, gst_rate: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none">
                                <option value="0">0%</option>
                                <option value="5">5%</option>
                                <option value="12">12%</option>
                                <option value="18">18%</option>
                                <option value="28">28%</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Unit Price (₹) *</label>
                            <input required type="number" step="0.01" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Unit *</label>
                            <select value={form.unit} onChange={e => setForm({ ...form, unit: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none">
                                <option value="PCS">Pieces (PCS)</option>
                                <option value="KG">Kilograms (KG)</option>
                                <option value="LTR">Litres (LTR)</option>
                                <option value="MTR">Meters (MTR)</option>
                                <option value="BOX">Box</option>
                                <option value="SQM">Sq. Meters</option>
                                <option value="HRS">Hours</option>
                                <option value="NOS">Numbers (NOS)</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Current Stock</label>
                            <input type="number" value={form.stock} onChange={e => setForm({ ...form, stock: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Low Stock Alert</label>
                            <input type="number" value={form.low_stock_threshold} onChange={e => setForm({ ...form, low_stock_threshold: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Description</label>
                            <input value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none" />
                        </div>
                        <div className="md:col-span-3 flex gap-3 justify-end">
                            <button type="button" onClick={resetForm} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200">Cancel</button>
                            <button type="submit" className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20">{editingId ? 'Update' : 'Save'} Product</button>
                        </div>
                    </form>
                </div>
            )}

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="overflow-x-auto">
                    {loading ? (
                        <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
                    ) : products.length === 0 ? (
                        <div className="p-16 text-center">
                            <Package size={48} className="mx-auto text-gray-300 mb-4" />
                            <h3 className="text-lg font-bold text-gray-900 mb-2">No products added</h3>
                            <p className="text-gray-500 max-w-sm mx-auto">Start by adding your first product or service.</p>
                        </div>
                    ) : (
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/80 border-b border-gray-100 uppercase text-xs font-semibold tracking-wider text-gray-500">
                                    <th className="p-4 pl-6">Item Code/Name</th>
                                    <th className="p-4">HSN/SAC</th>
                                    <th className="p-4">GST Rate</th>
                                    <th className="p-4">Price</th>
                                    <th className="p-4">Unit</th>
                                    <th className="p-4">Stock</th>
                                    <th className="p-4 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {products.map((p) => (
                                    <tr key={p.id} className="hover:bg-gray-50/50 transition-colors group">
                                        <td className="p-4 pl-6">
                                            <p className="font-bold text-gray-900">{p.name}</p>
                                            <p className="text-xs text-gray-500 font-medium tracking-wide">{p.description || 'No desc'}</p>
                                        </td>
                                        <td className="p-4 font-medium text-gray-600">{p.hsn_sac}</td>
                                        <td className="p-4">
                                            <span className="inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-purple-50 text-purple-600 border border-purple-100">
                                                {p.gst_rate}%
                                            </span>
                                        </td>
                                        <td className="p-4 font-bold text-gray-900">₹{p.price}</td>
                                        <td className="p-4 text-gray-600 font-medium">{p.unit}</td>
                                        <td className="p-4">
                                            <div className={`flex items-center gap-2 font-medium ${p.is_low_stock ? 'text-rose-600' : 'text-emerald-600'}`}>
                                                {p.is_low_stock && <AlertTriangle size={14} />}
                                                <Database size={14} className="opacity-50" /> {p.stock} {p.unit}
                                            </div>
                                        </td>
                                        <td className="p-4 text-center">
                                            <div className="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button onClick={() => handleEdit(p)} className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg"><Edit2 size={16} /></button>
                                                <button onClick={() => handleDelete(p.id)} className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg"><Trash2 size={16} /></button>
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

export default Products;
