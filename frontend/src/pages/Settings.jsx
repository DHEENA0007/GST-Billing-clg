import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Save, Building, MapPin, Hash, Phone, Landmark, Calendar, FileText, Lock, Eye, EyeOff, Check } from 'lucide-react';

const INDIAN_STATES = [
    { code: '01', name: 'Jammu & Kashmir' }, { code: '02', name: 'Himachal Pradesh' }, { code: '03', name: 'Punjab' }, { code: '04', name: 'Chandigarh' },
    { code: '05', name: 'Uttarakhand' }, { code: '06', name: 'Haryana' }, { code: '07', name: 'Delhi' }, { code: '08', name: 'Rajasthan' },
    { code: '09', name: 'Uttar Pradesh' }, { code: '10', name: 'Bihar' }, { code: '11', name: 'Sikkim' }, { code: '12', name: 'Arunachal Pradesh' },
    { code: '13', name: 'Nagaland' }, { code: '14', name: 'Manipur' }, { code: '15', name: 'Mizoram' }, { code: '16', name: 'Tripura' },
    { code: '17', name: 'Meghalaya' }, { code: '18', name: 'Assam' }, { code: '19', name: 'West Bengal' }, { code: '20', name: 'Jharkhand' },
    { code: '21', name: 'Odisha' }, { code: '22', name: 'Chhattisgarh' }, { code: '23', name: 'Madhya Pradesh' }, { code: '24', name: 'Gujarat' },
    { code: '25', name: 'Daman & Diu' }, { code: '26', name: 'Dadra & Nagar Haveli' }, { code: '27', name: 'Maharashtra' }, { code: '28', name: 'Andhra Pradesh (Old)' },
    { code: '29', name: 'Karnataka' }, { code: '30', name: 'Goa' }, { code: '31', name: 'Lakshadweep' }, { code: '32', name: 'Kerala' },
    { code: '33', name: 'Tamil Nadu' }, { code: '34', name: 'Puducherry' }, { code: '35', name: 'Andaman & Nicobar' }, { code: '36', name: 'Telangana' },
    { code: '37', name: 'Andhra Pradesh (New)' }, { code: '38', name: 'Ladakh' },
];

const Settings = () => {
    const { token, user } = useContext(AuthContext);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState({ text: '', type: '' });
    const [activeTab, setActiveTab] = useState('company');

    // Password change
    const [passwords, setPasswords] = useState({ old_password: '', new_password: '', confirm_password: '' });
    const [showOld, setShowOld] = useState(false);
    const [showNew, setShowNew] = useState(false);
    const [pwLoading, setPwLoading] = useState(false);

    const [settings, setSettings] = useState({
        id: null, company_name: '', gstin: '', address: '', state_code: '29',
        phone: '', email: '', bank_name: '', account_number: '', ifsc_code: '',
        financial_year: '2025-2026', invoice_prefix: 'INV'
    });

    useEffect(() => { fetchSettings(); }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const res = await axios.get('/api/company-settings/', { headers: { Authorization: `Bearer ${token}` } });
            if (res.data) setSettings(res.data);
        } catch (err) { console.error(err); setMessage({ text: 'Failed to load settings', type: 'error' }); }
        finally { setLoading(false); }
    };

    const handleSave = async (e) => {
        e.preventDefault();
        setSaving(true);
        setMessage({ text: '', type: '' });
        try {
            await axios.put(`/api/company-settings/${settings.id}/`, settings, { headers: { Authorization: `Bearer ${token}` } });
            setMessage({ text: 'Company settings updated successfully!', type: 'success' });
        } catch (err) { setMessage({ text: 'Failed to save settings. Check permissions.', type: 'error' }); }
        finally { setSaving(false); }
    };

    const handlePasswordChange = async (e) => {
        e.preventDefault();
        if (passwords.new_password !== passwords.confirm_password) {
            setMessage({ text: 'New passwords do not match!', type: 'error' }); return;
        }
        if (passwords.new_password.length < 6) {
            setMessage({ text: 'Password must be at least 6 characters', type: 'error' }); return;
        }
        setPwLoading(true);
        try {
            await axios.post('/api/auth/change-password/', {
                old_password: passwords.old_password, new_password: passwords.new_password
            }, { headers: { Authorization: `Bearer ${token}` } });
            setMessage({ text: 'Password changed successfully!', type: 'success' });
            setPasswords({ old_password: '', new_password: '', confirm_password: '' });
        } catch (err) {
            setMessage({ text: err.response?.data?.detail || 'Failed to change password', type: 'error' });
        } finally { setPwLoading(false); }
    };

    const tabs = [
        { id: 'company', label: 'Company Profile', icon: <Building size={16} /> },
        { id: 'tax', label: 'Tax & Invoicing', icon: <FileText size={16} /> },
        { id: 'bank', label: 'Bank Details', icon: <Landmark size={16} /> },
        { id: 'password', label: 'Change Password', icon: <Lock size={16} /> },
    ];

    if (user?.profile?.role !== 'ADMIN' && activeTab !== 'password') {
        // Non-admins can only change password
        return (
            <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-2xl mx-auto">
                <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-2"><Lock className="text-indigo-600" /> Change Password</h2>
                {message.text && <div className={`p-4 rounded-xl font-bold text-sm ${message.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>{message.text}</div>}
                <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                    <form onSubmit={handlePasswordChange} className="space-y-5 max-w-md">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">Current Password</label>
                            <input type="password" required value={passwords.old_password} onChange={e => setPasswords({ ...passwords, old_password: e.target.value })}
                                className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">New Password</label>
                            <input type="password" required minLength={6} value={passwords.new_password} onChange={e => setPasswords({ ...passwords, new_password: e.target.value })}
                                className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">Confirm Password</label>
                            <input type="password" required minLength={6} value={passwords.confirm_password} onChange={e => setPasswords({ ...passwords, confirm_password: e.target.value })}
                                className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                        </div>
                        <button type="submit" disabled={pwLoading} className="px-6 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/20 hover:bg-indigo-700">
                            {pwLoading ? 'Changing...' : 'Update Password'}
                        </button>
                    </form>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-4xl mx-auto">
            <div>
                <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-2">
                    <Building className="text-indigo-600" /> Settings & Configuration
                </h2>
                <p className="text-gray-500 mt-1 font-medium">Manage your business profile, tax settings, and account.</p>
            </div>

            {message.text && (
                <div className={`p-4 rounded-xl font-bold text-sm flex items-center gap-2 ${message.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
                    {message.type === 'success' && <Check size={16} />} {message.text}
                </div>
            )}

            {/* Tabs */}
            <div className="flex gap-2">
                {tabs.map(tab => (
                    <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                        className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all ${activeTab === tab.id ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
                            }`}>
                        {tab.icon} {tab.label}
                    </button>
                ))}
            </div>

            {loading ? (
                <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
            ) : (
                <>
                    {/* Company Profile */}
                    {activeTab === 'company' && (
                        <form onSubmit={handleSave} className="space-y-6">
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Building size={20} className="text-indigo-500" /> Business Details</h3>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div className="md:col-span-2">
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Company Name (As per GST) *</label>
                                        <input type="text" required className="w-full bg-gray-50/50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-medium"
                                            value={settings.company_name} onChange={e => setSettings({ ...settings, company_name: e.target.value })} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">GSTIN Number *</label>
                                        <div className="relative">
                                            <Hash className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                            <input type="text" required className="w-full pl-10 bg-gray-50/50 border border-gray-200 p-3 rounded-xl outline-none uppercase font-bold"
                                                placeholder="29ABCDE1234F1Z5" value={settings.gstin} onChange={e => setSettings({ ...settings, gstin: e.target.value })} />
                                        </div>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">State *</label>
                                        <div className="relative">
                                            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                            <select className="w-full pl-10 bg-gray-50/50 border border-gray-200 p-3 rounded-xl outline-none font-medium"
                                                value={settings.state_code} onChange={e => setSettings({ ...settings, state_code: e.target.value })}>
                                                {INDIAN_STATES.map(s => <option key={s.code} value={s.code}>{s.name} ({s.code})</option>)}
                                            </select>
                                        </div>
                                    </div>
                                    <div className="md:col-span-2">
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Registered Address</label>
                                        <textarea rows="3" className="w-full bg-gray-50/50 border border-gray-200 p-3 rounded-xl outline-none font-medium resize-none"
                                            value={settings.address} onChange={e => setSettings({ ...settings, address: e.target.value })}></textarea>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Phone</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.phone} onChange={e => setSettings({ ...settings, phone: e.target.value })} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Email</label>
                                        <input type="email" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.email} onChange={e => setSettings({ ...settings, email: e.target.value })} />
                                    </div>
                                </div>
                            </div>
                            <div className="flex justify-end">
                                <button type="submit" disabled={saving} className="px-8 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 flex items-center gap-2">
                                    {saving ? 'Saving...' : <><Save size={18} /> Update Profile</>}
                                </button>
                            </div>
                        </form>
                    )}

                    {/* Tax & Invoicing */}
                    {activeTab === 'tax' && (
                        <form onSubmit={handleSave} className="space-y-6">
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><FileText size={20} className="text-indigo-500" /> Tax & Invoice Configuration</h3>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Financial Year</label>
                                        <div className="relative">
                                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                            <select className="w-full pl-10 bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none font-medium"
                                                value={settings.financial_year} onChange={e => setSettings({ ...settings, financial_year: e.target.value })}>
                                                <option value="2023-2024">2023-2024</option>
                                                <option value="2024-2025">2024-2025</option>
                                                <option value="2025-2026">2025-2026</option>
                                                <option value="2026-2027">2026-2027</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Invoice Number Prefix</label>
                                        <input type="text" placeholder="INV" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none uppercase font-bold"
                                            value={settings.invoice_prefix} onChange={e => setSettings({ ...settings, invoice_prefix: e.target.value })} />
                                        <p className="text-xs text-gray-400 mt-1">Preview: {settings.invoice_prefix || 'INV'}-000001</p>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Currency</label>
                                        <select className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none font-medium" disabled>
                                            <option>INR (₹) — Indian Rupee</option>
                                        </select>
                                        <p className="text-xs text-gray-400 mt-1">GST is INR-only by regulation</p>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Tax Regime</label>
                                        <select className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none font-medium" disabled>
                                            <option>Regular (CGST + SGST / IGST)</option>
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div className="flex justify-end">
                                <button type="submit" disabled={saving} className="px-8 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 flex items-center gap-2">
                                    {saving ? 'Saving...' : <><Save size={18} /> Save Settings</>}
                                </button>
                            </div>
                        </form>
                    )}

                    {/* Bank Details */}
                    {activeTab === 'bank' && (
                        <form onSubmit={handleSave} className="space-y-6">
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Landmark size={20} className="text-amber-500" /> Bank Account Details</h3>
                                <p className="text-sm text-gray-500 mb-6">These details will appear on your invoices for payment.</p>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div className="md:col-span-2">
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Bank Name</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none font-medium" value={settings.bank_name} onChange={e => setSettings({ ...settings, bank_name: e.target.value })} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Account Number</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none font-medium" value={settings.account_number} onChange={e => setSettings({ ...settings, account_number: e.target.value })} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">IFSC Code</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none uppercase font-bold" value={settings.ifsc_code} onChange={e => setSettings({ ...settings, ifsc_code: e.target.value })} />
                                    </div>
                                </div>
                            </div>
                            <div className="flex justify-end">
                                <button type="submit" disabled={saving} className="px-8 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 flex items-center gap-2">
                                    {saving ? 'Saving...' : <><Save size={18} /> Save Bank Details</>}
                                </button>
                            </div>
                        </form>
                    )}

                    {/* Change Password */}
                    {activeTab === 'password' && (
                        <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                            <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Lock size={20} className="text-indigo-500" /> Change Password</h3>
                            <form onSubmit={handlePasswordChange} className="space-y-5 max-w-md">
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Current Password</label>
                                    <div className="relative">
                                        <input type={showOld ? 'text' : 'password'} required value={passwords.old_password} onChange={e => setPasswords({ ...passwords, old_password: e.target.value })}
                                            className="w-full bg-gray-50 border border-gray-200 p-3 pr-12 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                                        <button type="button" onClick={() => setShowOld(!showOld)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                                            {showOld ? <EyeOff size={18} /> : <Eye size={18} />}
                                        </button>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">New Password</label>
                                    <div className="relative">
                                        <input type={showNew ? 'text' : 'password'} required minLength={6} value={passwords.new_password} onChange={e => setPasswords({ ...passwords, new_password: e.target.value })}
                                            className="w-full bg-gray-50 border border-gray-200 p-3 pr-12 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                                        <button type="button" onClick={() => setShowNew(!showNew)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                                            {showNew ? <EyeOff size={18} /> : <Eye size={18} />}
                                        </button>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Confirm New Password</label>
                                    <input type="password" required minLength={6} value={passwords.confirm_password} onChange={e => setPasswords({ ...passwords, confirm_password: e.target.value })}
                                        className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500" />
                                    {passwords.confirm_password && passwords.new_password !== passwords.confirm_password && (
                                        <p className="text-xs text-rose-500 font-semibold mt-1">Passwords do not match</p>
                                    )}
                                </div>
                                <button type="submit" disabled={pwLoading} className="px-6 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/20 hover:bg-indigo-700 flex items-center gap-2">
                                    {pwLoading ? 'Changing...' : <><Lock size={16} /> Update Password</>}
                                </button>
                            </form>
                        </div>
                    )}
                </>
            )}
        </div>
    );
};

export default Settings;
