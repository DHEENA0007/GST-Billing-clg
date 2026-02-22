import React, { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Save, Plus, Trash2, ArrowLeft, User, FileText, Calculator } from 'lucide-react';

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
        status: 'DRAFT',
        invoice_type: 'TAX',
        notes: ''
    });

    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => { fetchInitialData(); }, []);

    const fetchInitialData = async () => {
        try {
            const hdrs = { headers: { Authorization: `Bearer ${token}` } };
            const [cusRes, prodRes] = await Promise.all([
                axios.get('/api/customers/', hdrs),
                axios.get('/api/products/', hdrs)
            ]);
            setCustomers(cusRes.data);
            setProducts(prodRes.data);
        } catch (error) { console.error("Failed to load data", error); }
    };

    const handleAddItem = () => {
        setItems([...items, { product_id: '', quantity: 1, unit_price: 0, gst_rate: 18, hsn: '' }]);
    };

    const handleItemChange = (index, field, value) => {
        const newItems = [...items];
        newItems[index][field] = value;
        if (field === 'product_id' && value) {
            const prod = products.find(p => p.id.toString() === value);
            if (prod) {
                newItems[index]['unit_price'] = prod.price;
                newItems[index]['gst_rate'] = prod.gst_rate;
                newItems[index]['hsn'] = prod.hsn_sac;
            }
        }
        setItems(newItems);
    };

    const removeItem = (index) => { setItems(items.filter((_, i) => i !== index)); };

    const getItemSubtotal = (item) => parseFloat(item.unit_price || 0) * parseFloat(item.quantity || 0);
    const getItemTax = (item) => getItemSubtotal(item) * (parseFloat(item.gst_rate || 0) / 100);
    const getItemTotal = (item) => getItemSubtotal(item) + getItemTax(item);

    const totals = items.reduce((acc, item) => {
        acc.subtotal += getItemSubtotal(item);
        acc.tax += getItemTax(item);
        acc.total += getItemTotal(item);
        return acc;
    }, { subtotal: 0, tax: 0, total: 0 });

    const handleSaveInvoice = async () => {
        if (!invoiceData.customer) { alert("Please select a customer"); return; }
        if (items.length === 0) { alert("Please add at least one item"); return; }

        setLoading(true);
        try {
            const hdrs = { headers: { Authorization: `Bearer ${token}` } };
            const invRes = await axios.post('/api/invoices/', invoiceData, hdrs);
            const invoiceId = invRes.data.id;

            for (const item of items) {
                if (item.product_id) {
                    await axios.post(`/api/invoices/${invoiceId}/add_item/`, item, hdrs);
                }
            }

            navigate('/invoices');
        } catch (error) {
            console.error(error);
            alert("Failed to save invoice: " + (error.response?.data?.detail || 'Unknown error'));
        } finally { setLoading(false); }
    };

    const fmt = (v) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(v);

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-5xl mx-auto">
            <div className="flex justify-between items-center">
                <div className="flex items-center gap-4">
                    <button onClick={() => navigate('/invoices')} className="p-2 bg-white rounded-xl shadow-sm border border-gray-100 text-gray-400 hover:text-indigo-600">
                        <ArrowLeft size={20} />
                    </button>
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900">Create New Invoice</h2>
                        <p className="text-gray-500 font-medium">Generate a {invoiceData.invoice_type === 'PROFORMA' ? 'proforma' : 'tax'} invoice</p>
                    </div>
                </div>
                <div className="flex gap-3">
                    <button onClick={() => { setInvoiceData({ ...invoiceData, status: 'DRAFT' }); handleSaveInvoice(); }} disabled={loading}
                        className="px-5 py-2.5 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl hover:bg-gray-50 shadow-sm flex items-center gap-2">
                        <FileText size={16} /> Save as Draft
                    </button>
                    <button onClick={() => { setInvoiceData({ ...invoiceData, status: 'ISSUED' }); handleSaveInvoice(); }} disabled={loading}
                        className="px-6 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 flex items-center gap-2">
                        {loading ? 'Saving...' : <><Save size={18} /> Save & Issue</>}
                    </button>
                </div>
            </div>

            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100 space-y-8">
                {/* Invoice Type + Info */}
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Type</label>
                        <select className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-medium"
                            value={invoiceData.invoice_type} onChange={(e) => setInvoiceData({ ...invoiceData, invoice_type: e.target.value })}>
                            <option value="TAX">Tax Invoice</option>
                            <option value="PROFORMA">Proforma Invoice</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Number</label>
                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-medium"
                            value={invoiceData.invoice_number} onChange={(e) => setInvoiceData({ ...invoiceData, invoice_number: e.target.value })} />
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Date</label>
                        <input type="date" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            value={invoiceData.date} onChange={(e) => setInvoiceData({ ...invoiceData, date: e.target.value })} />
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Due Date</label>
                        <input type="date" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            value={invoiceData.due_date} onChange={(e) => setInvoiceData({ ...invoiceData, due_date: e.target.value })} />
                    </div>
                </div>

                {/* Customer Selection */}
                <div className="p-6 bg-indigo-50/50 rounded-2xl border border-indigo-100/50">
                    <label className="block text-sm font-bold text-indigo-900 mb-2 flex items-center gap-2"><User size={16} /> Bill To Customer</label>
                    <select className="w-full bg-white border border-indigo-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-medium"
                        value={invoiceData.customer} onChange={(e) => setInvoiceData({ ...invoiceData, customer: e.target.value })}>
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
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-20">HSN</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-20">QTY</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-28">Rate (₹)</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-20">GST %</th>
                                    <th className="p-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-28 text-right">Total</th>
                                    <th className="p-4 w-12"></th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 bg-white">
                                {items.length === 0 && (
                                    <tr><td colSpan="7" className="p-8 text-center text-gray-400 font-medium">No items added yet. Click 'Add Product'.</td></tr>
                                )}
                                {items.map((item, idx) => (
                                    <tr key={idx} className="hover:bg-gray-50/50">
                                        <td className="p-3">
                                            <select className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg outline-none text-sm font-medium"
                                                value={item.product_id} onChange={(e) => handleItemChange(idx, 'product_id', e.target.value)}>
                                                <option value="">Select Item</option>
                                                {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                                            </select>
                                        </td>
                                        <td className="p-3">
                                            <input className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg text-center text-sm outline-none" value={item.hsn} readOnly />
                                        </td>
                                        <td className="p-3">
                                            <input type="number" min="1" className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg text-center text-sm outline-none"
                                                value={item.quantity} onChange={(e) => handleItemChange(idx, 'quantity', e.target.value)} />
                                        </td>
                                        <td className="p-3">
                                            <input type="number" step="0.01" className="w-full bg-gray-50 border border-gray-200 p-2.5 rounded-lg text-sm outline-none"
                                                value={item.unit_price} onChange={(e) => handleItemChange(idx, 'unit_price', e.target.value)} />
                                        </td>
                                        <td className="p-3 text-center text-sm font-bold text-gray-600">{item.gst_rate}%</td>
                                        <td className="p-3 text-right font-bold text-gray-900 text-sm">{fmt(getItemTotal(item))}</td>
                                        <td className="p-3 text-center">
                                            <button onClick={() => removeItem(idx)} className="text-gray-400 hover:text-rose-500"><Trash2 size={16} /></button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Totals + Notes */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">Notes / Terms</label>
                        <textarea rows="4" placeholder="Payment terms, special instructions, thank you note..."
                            className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none resize-none font-medium text-sm"
                            value={invoiceData.notes} onChange={e => setInvoiceData({ ...invoiceData, notes: e.target.value })}></textarea>
                    </div>
                    <div className="bg-gray-50 rounded-2xl p-6">
                        <h4 className="font-bold text-gray-900 mb-4 flex items-center gap-2"><Calculator size={16} className="text-indigo-600" /> Summary</h4>
                        <div className="space-y-3">
                            <div className="flex justify-between text-sm"><span className="text-gray-500">Subtotal</span><span className="font-medium">{fmt(totals.subtotal)}</span></div>
                            <div className="flex justify-between text-sm"><span className="text-gray-500">GST</span><span className="font-medium">{fmt(totals.tax)}</span></div>
                            <div className="border-t border-gray-200 pt-3 flex justify-between">
                                <span className="font-bold text-gray-900">Grand Total</span>
                                <span className="font-black text-xl text-indigo-600">{fmt(totals.total)}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreateInvoice;
