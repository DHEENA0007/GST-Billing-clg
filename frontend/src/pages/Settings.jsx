import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Save, Building, MapPin, Hash, Phone, Mail, Landmark } from 'lucide-react';

const Settings = () => {
    const { token, user } = useContext(AuthContext);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState({ text: '', type: '' });

    const [settings, setSettings] = useState({
        id: null,
        company_name: '',
        gstin: '',
        address: '',
        state_code: '29',
        phone: '',
        email: '',
        bank_name: '',
        account_number: '',
        ifsc_code: ''
    });

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const res = await axios.get('/api/company-settings/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            // The API returns the single settings object via list() in the ViewSet
            if (res.data) {
                setSettings(res.data);
            }
        } catch (err) {
            console.error(err);
            setMessage({ text: 'Failed to load settings', type: 'error' });
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async (e) => {
        e.preventDefault();
        setSaving(true);
        setMessage({ text: '', type: '' });

        try {
            await axios.put(`/api/company-settings/${settings.id}/`, settings, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setMessage({ text: 'Company settings updated successfully!', type: 'success' });
        } catch (err) {
            console.error(err);
            setMessage({ text: 'Failed to save settings. Check permissions.', type: 'error' });
        } finally {
            setSaving(false);
        }
    };

    if (user?.profile?.role !== 'ADMIN') {
        return (
            <div className="flex flex-col items-center justify-center p-20 text-center">
                <div className="w-20 h-20 bg-rose-50 rounded-full flex items-center justify-center mb-4">
                    <Building className="text-rose-500 w-10 h-10" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900">Access Restricted</h2>
                <p className="text-gray-500 mt-2">Only Administrators can modify company settings.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-4xl mx-auto">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-2">
                        <Building className="text-indigo-600" /> Company Profile Setup
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium">Configure your business details and GST information.</p>
                </div>
            </div>

            {message.text && (
                <div className={`p-4 rounded-xl font-bold text-sm ${message.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
                    {message.text}
                </div>
            )}

            {loading ? (
                <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
            ) : (
                <form onSubmit={handleSave} className="space-y-8">

                    {/* General Info */}
                    <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                        <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Building size={20} className="text-indigo-500" /> Business Details</h3>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="col-span-1 md:col-span-2">
                                <label className="block text-sm font-bold text-gray-700 mb-2">Company Name (As per GST)</label>
                                <input
                                    type="text" required
                                    className="w-full bg-gray-50/50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none font-medium"
                                    value={settings.company_name}
                                    onChange={e => setSettings({ ...settings, company_name: e.target.value })}
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">GSTIN Number</label>
                                <div className="relative">
                                    <Hash className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                    <input
                                        type="text" required
                                        className="w-full pl-10 bg-gray-50/50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none uppercase font-bold text-gray-900"
                                        placeholder="29ABCDE1234F1Z5"
                                        value={settings.gstin}
                                        onChange={e => setSettings({ ...settings, gstin: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">State Code (crucial for CGST/IGST)</label>
                                <div className="relative">
                                    <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                    <select
                                        className="w-full pl-10 bg-gray-50/50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all outline-none font-medium"
                                        value={settings.state_code}
                                        onChange={e => setSettings({ ...settings, state_code: e.target.value })}
                                    >
                                        <option value="27">Maharashtra (27)</option>
                                        <option value="29">Karnataka (29)</option>
                                        <option value="07">Delhi (07)</option>
                                        <option value="33">Tamil Nadu (33)</option>
                                        {/* Add more as needed */}
                                    </select>
                                </div>
                            </div>

                            <div className="col-span-1 md:col-span-2">
                                <label className="block text-sm font-bold text-gray-700 mb-2">Registered Address</label>
                                <textarea
                                    rows="3"
                                    className="w-full bg-gray-50/50 border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all outline-none font-medium resize-none"
                                    value={settings.address}
                                    onChange={e => setSettings({ ...settings, address: e.target.value })}
                                ></textarea>
                            </div>
                        </div>
                    </div>

                    {/* Contact & Bank */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                            <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Phone size={20} className="text-emerald-500" /> Contact Info</h3>
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Phone</label>
                                    <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.phone} onChange={e => setSettings({ ...settings, phone: e.target.value })} />
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Support Email</label>
                                    <input type="email" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.email} onChange={e => setSettings({ ...settings, email: e.target.value })} />
                                </div>
                            </div>
                        </div>

                        <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                            <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Landmark size={20} className="text-amber-500" /> Payment & Bank</h3>
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Bank Name</label>
                                    <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.bank_name} onChange={e => setSettings({ ...settings, bank_name: e.target.value })} />
                                </div>
                                <div className="flex gap-3">
                                    <div className="flex-1">
                                        <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Account No</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none" value={settings.account_number} onChange={e => setSettings({ ...settings, account_number: e.target.value })} />
                                    </div>
                                    <div className="w-1/3">
                                        <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">IFSC</label>
                                        <input type="text" className="w-full bg-gray-50 border border-gray-200 p-3 rounded-xl outline-none uppercase" value={settings.ifsc_code} onChange={e => setSettings({ ...settings, ifsc_code: e.target.value })} />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="flex justify-end pt-4">
                        <button
                            type="submit"
                            disabled={saving}
                            className="px-8 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/30 hover:bg-indigo-700 transition-all flex items-center gap-2"
                        >
                            {saving ? 'Saving Profile...' : <><Save size={18} /> Update Profile</>}
                        </button>
                    </div>
                </form>
            )}
        </div>
    );
};

export default Settings;
