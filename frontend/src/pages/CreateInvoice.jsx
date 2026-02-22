import React, { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Save, Plus, Trash2, ArrowLeft, Building2, User } from 'lucide-react';

const CreateInvoice = () => {
    const { token } = useContext(AuthContext);
    const navigate = useNavigate();

    const [customers, setCustomers] = useState([]);
    const [products, setProducts] = useState([]);

    const [invoiceData, setInvoiceData] = useState({
        invoice_number: `INV-${Date.now().toString().slice(-6)}`,
        customer: '',
        date: new Date().toISOString().split('T')[0],
        due_date: '',
        status: 'DRAFT'
    });

    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        fetchInitialData();
    }, []);

    const fetchInitialData = async () => {
        try {
            const hdrs = { headers: { Authorization: `Bearer ${token}` } };
            const [cusRes, prodRes] = await Promise.all([
                axios.get('/api/customers/', hdrs),
                axios.get('/api/products/', hdrs)
            ]);
            setCustomers(cusRes.data);
            setProducts(prodRes.data);
        } catch (error) {
            console.error("Failed to load data", error);
        }
    };

    const handleAddItem = () => {
        setItems([...items, { product_id: '', quantity: 1, unit_price: 0 }]);
    };

    const handleItemChange = (index, field, value) => {
        const newItems = [...items];
        newItems[index][field] = value;

        // Auto populate price if product selected
        if (field === 'product_id' && value) {
            const prod = products.find(p => p.id.toString() === value);
            if (prod) {
                newItems[index]['unit_price'] = prod.price;
            }
        }
        setItems(newItems);
    };

    const removeItem = (index) => {
        setItems(items.filter((_, i) => i !== index));
    };

    const handleSaveInvoice = async () => {
        if (!invoiceData.customer) {
            alert("Please select a customer");
            return;
        }

        setLoading(true);
        try {
            const hdrs = { headers: { Authorization: `Bearer ${token}` } };

            // 1. Create Invoice Core
            const invRes = await axios.post('/api/invoices/', invoiceData, hdrs);
            const invoiceId = invRes.data.id;

            // 2. Add all items sequentially
            for (const item of items) {
                if (item.product_id) {
                    await axios.post(`/api/invoices/${invoiceId}/add_item/`, item, hdrs);
                }
            }

            navigate('/invoices');
        } catch (error) {
            console.error(error);
            alert("Failed to save invoice");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-5xl mx-auto">
            <div className="flex justify-between items-center">
                <div className="flex items-center gap-4">
                    <button onClick={() => navigate('/invoices')} className="p-2 bg-white rounded-xl shadow-sm border border-gray-100 text-gray-400 hover:text-indigo-600">
                        <ArrowLeft size={20} />
                    </button>
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900">Create New Invoice</h2>
                        <p className="text-gray-500 font-medium">Generate a tax invoice for goods/services</p>
                    </div>
                </div>
                <button
                    onClick={handleSaveInvoice}
                    disabled={loading}
                    className="px-6 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 flex items-center gap-2"
                >
                    {loading ? 'Saving...' : <><Save size={18} /> Save Invoice</>}
                </button>
            </div>

            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100 space-y-8">
                {/* Invoice Info */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Number</label>
                        <input
                            type="text"
                            className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            value={invoiceData.invoice_number}
                            onChange={(e) => setInvoiceData({ ...invoiceData, invoice_number: e.target.value })}
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Date</label>
                        <input
                            type="date"
                            className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            value={invoiceData.date}
                            onChange={(e) => setInvoiceData({ ...invoiceData, date: e.target.value })}
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Due Date</label>
                        <input
                            type="date"
                            className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            value={invoiceData.due_date}
                            onChange={(e) => setInvoiceData({ ...invoiceData, due_date: e.target.value })}
                        />
                    </div>
                </div>

                {/* Customer Selection */}
                <div className="p-6 bg-indigo-50/50 rounded-2xl border border-indigo-100/50">
                    <label className="block text-sm font-bold text-indigo-900 mb-2 flex items-center gap-2"><User size={16} /> Bill To Customer</label>
                    <select
                        className="w-full bg-white border border-indigo-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-medium"
                        value={invoiceData.customer}
                        onChange={(e) => setInvoiceData({ ...invoiceData, customer: e.target.value })}
                    >
                        <option value="">-- Select Customer --</option>
                        {customers.map(c => <option key={c.id} value={c.id}>{c.name} (GSTIN: {c.gstin || 'N/A'})</option>)}
                    </select>
                </div>

                {/* Line Items */}
                <div>
                    <div className="flex justify-between items-end mb-4">
                        <h3 className="text-lg font-bold text-gray-900">Line Items</h3>
                        <button onClick={handleAddItem} className="text-sm font-bold text-indigo-600 bg-indigo-50 px-4 py-2 rounded-lg hover:bg-indigo-100 flex items-center gap-1">
                            <Plus size={16} /> Add Product
                        </button>
                    </div>

                    <div className="border border-gray-200 rounded-2xl overflow-hidden">
                        <table className="w-full text-left">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Product / Service</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-24">QTY</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-32">Rate</th>
                                    <th className="p-4 w-16"></th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 bg-white">
                                {items.length === 0 && (
                                    <tr>
                                        <td colSpan="4" className="p-8 text-center text-gray-400 font-medium">No items added yet. Click 'Add Product'.</td>
                                    </tr>
                                )}
                                {items.map((item, idx) => (
                                    <tr key={idx}>
                                        <td className="p-4">
                                            <select
                                                className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg outline-none"
                                                value={item.product_id}
                                                onChange={(e) => handleItemChange(idx, 'product_id', e.target.value)}
                                            >
                                                <option value="">Select Item</option>
                                                {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                                            </select>
                                        </td>
                                        <td className="p-4">
                                            <input
                                                type="number" min="1"
                                                className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg w-full text-center outline-none"
                                                value={item.quantity}
                                                onChange={(e) => handleItemChange(idx, 'quantity', e.target.value)}
                                            />
                                        </td>
                                        <td className="p-4">
                                            <input
                                                type="number" step="0.01"
                                                className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg w-full outline-none"
                                                value={item.unit_price}
                                                onChange={(e) => handleItemChange(idx, 'unit_price', e.target.value)}
                                            />
                                        </td>
                                        <td className="p-4 text-center">
                                            <button onClick={() => removeItem(idx)} className="text-gray-400 hover:text-rose-500"><Trash2 size={18} /></button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreateInvoice;
