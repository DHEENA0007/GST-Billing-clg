import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Shield, ShieldAlert, UserCheck, Search, Trash2, Edit2, ShieldCheck, Mail, Phone, Briefcase, UserPlus, X, Eye, EyeOff, Save, Check } from 'lucide-react';

const RoleManagement = () => {
    const { token, user } = useContext(AuthContext);
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const [message, setMessage] = useState({ text: '', type: '' });

    // Add User Form State
    const [showAddForm, setShowAddForm] = useState(false);
    const [showPassword, setShowPassword] = useState(false);
    const [addForm, setAddForm] = useState({
        username: '', password: '', email: '', first_name: '', last_name: '', role: 'SALES', phone: ''
    });
    const [addLoading, setAddLoading] = useState(false);

    // Edit State
    const [editingUserId, setEditingUserId] = useState(null);
    const [editRole, setEditRole] = useState('');

    const API_URL = '/api/roles/';
    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchUsers(); }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const res = await axios.get(API_URL, hdrs);
            setUsers(res.data);
            setError('');
        } catch (err) {
            if (err.response?.status === 403) {
                setError("You don't have permission to view role management. Only Administrators can access this page.");
            } else {
                setError('Failed to fetch users. Please try again.');
            }
        } finally {
            setLoading(false);
        }
    };

    const resetAddForm = () => {
        setAddForm({ username: '', password: '', email: '', first_name: '', last_name: '', role: 'SALES', phone: '' });
        setShowAddForm(false);
        setShowPassword(false);
        setMessage({ text: '', type: '' });
    };

    const handleAddUser = async (e) => {
        e.preventDefault();
        setAddLoading(true);
        setMessage({ text: '', type: '' });

        try {
            const res = await axios.post(API_URL, addForm, hdrs);
            setUsers([res.data, ...users]);
            resetAddForm();
            setMessage({ text: `User "${addForm.username}" created successfully with ${addForm.role} role!`, type: 'success' });
            setTimeout(() => setMessage({ text: '', type: '' }), 5000);
        } catch (err) {
            setMessage({ text: err.response?.data?.detail || 'Failed to create user', type: 'error' });
        } finally {
            setAddLoading(false);
        }
    };

    const startEdit = (u) => {
        setEditingUserId(u.id);
        setEditRole(u.profile?.role || 'SALES');
    };

    const cancelEdit = () => {
        setEditingUserId(null);
        setEditRole('');
    };

    const handleUpdateRole = async (userId) => {
        try {
            await axios.patch(`${API_URL}${userId}/`, { role: editRole }, hdrs);
            setUsers(users.map(u => {
                if (u.id === userId) {
                    return { ...u, profile: { ...u.profile, role: editRole } };
                }
                return u;
            }));
            cancelEdit();
            setMessage({ text: 'Role updated successfully!', type: 'success' });
            setTimeout(() => setMessage({ text: '', type: '' }), 3000);
        } catch (err) {
            alert(err.response?.data?.detail || 'Failed to update role');
        }
    };

    const handleDeleteUser = async (userId, username) => {
        if (!window.confirm(`Are you sure you want to delete user "${username}"? This cannot be undone.`)) return;
        try {
            await axios.delete(`${API_URL}${userId}/`, hdrs);
            setUsers(users.filter(u => u.id !== userId));
            setMessage({ text: `User "${username}" deleted.`, type: 'success' });
            setTimeout(() => setMessage({ text: '', type: '' }), 3000);
        } catch (err) {
            alert(err.response?.data?.detail || 'Failed to delete user');
        }
    };

    const getRoleBadge = (role) => {
        switch (role) {
            case 'ADMIN':
                return <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider bg-rose-50 text-rose-600 border border-rose-100"><ShieldAlert size={12} /> Admin</span>;
            case 'ACCOUNTANT':
                return <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider bg-purple-50 text-purple-600 border border-purple-100"><Briefcase size={12} /> Accountant</span>;
            case 'SALES':
            default:
                return <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider bg-emerald-50 text-emerald-600 border border-emerald-100"><UserCheck size={12} /> Sales</span>;
        }
    };

    const getRoleDescription = (role) => {
        switch (role) {
            case 'ADMIN': return 'Full access to all modules including user management, settings, and reports.';
            case 'ACCOUNTANT': return 'Access to invoices, payments, reports, GST filings, and financial data.';
            case 'SALES': return 'Access to customers, products, and invoice creation.';
            default: return '';
        }
    };

    const filteredUsers = users.filter(u => {
        const q = searchQuery.toLowerCase();
        return u.username.toLowerCase().includes(q) ||
            (u.first_name || '').toLowerCase().includes(q) ||
            (u.last_name || '').toLowerCase().includes(q) ||
            (u.email || '').toLowerCase().includes(q);
    });

    const roleCounts = {
        ADMIN: users.filter(u => u.profile?.role === 'ADMIN').length,
        ACCOUNTANT: users.filter(u => u.profile?.role === 'ACCOUNTANT').length,
        SALES: users.filter(u => u.profile?.role === 'SALES').length,
    };

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center h-[70vh] text-center animate-in fade-in duration-500">
                <div className="w-24 h-24 bg-rose-50 flex items-center justify-center rounded-3xl mb-6 shadow-sm border border-rose-100">
                    <ShieldAlert size={48} className="text-rose-500" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">Access Denied</h2>
                <p className="text-gray-500 max-w-md">{error}</p>
            </div>
        );
    }

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <ShieldCheck className="text-indigo-600" size={28} />
                        Role & Access Management
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Create users, assign roles, and control access to modules.</p>
                </div>
                <div className="flex gap-3">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            placeholder="Search users..."
                            value={searchQuery}
                            onChange={e => setSearchQuery(e.target.value)}
                            className="w-64 bg-white border border-gray-200 text-sm rounded-xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all font-medium text-gray-900 shadow-sm"
                        />
                    </div>
                    <button
                        onClick={() => { resetAddForm(); setShowAddForm(true); }}
                        className="px-5 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 transform hover:-translate-y-0.5"
                    >
                        <UserPlus size={18} /> Add User
                    </button>
                </div>
            </div>

            {/* Success / Error Messages */}
            {message.text && (
                <div className={`p-4 rounded-xl text-sm font-semibold flex items-center gap-3 animate-in slide-in-from-top-2 ${message.type === 'success' ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-rose-50 text-rose-700 border border-rose-100'
                    }`}>
                    {message.type === 'success' ? <Check size={18} /> : <ShieldAlert size={18} />}
                    {message.text}
                </div>
            )}

            {/* Role Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {[
                    { role: 'ADMIN', label: 'Administrators', color: 'rose', icon: <ShieldAlert size={20} />, desc: 'Full system access' },
                    { role: 'ACCOUNTANT', label: 'Accountants', color: 'purple', icon: <Briefcase size={20} />, desc: 'Financial access' },
                    { role: 'SALES', label: 'Sales Reps', color: 'emerald', icon: <UserCheck size={20} />, desc: 'Customer & product access' },
                ].map(r => (
                    <div key={r.role} className={`bg-white rounded-2xl p-5 shadow-sm border border-gray-100 flex items-center gap-4 hover:shadow-md transition-all`}>
                        <div className={`w-12 h-12 rounded-xl bg-${r.color}-50 flex items-center justify-center text-${r.color}-600`}>
                            {r.icon}
                        </div>
                        <div>
                            <p className="text-2xl font-black text-gray-900 tracking-tight">{roleCounts[r.role]}</p>
                            <p className="text-sm text-gray-500 font-medium">{r.label}</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Add User Form */}
            {showAddForm && (
                <div className="bg-white rounded-3xl p-8 shadow-lg border border-gray-100 animate-in slide-in-from-top-4 duration-300">
                    <div className="flex justify-between items-center mb-6">
                        <div>
                            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2"><UserPlus size={20} className="text-indigo-600" /> Create New User</h3>
                            <p className="text-sm text-gray-500 mt-1">Add a team member and assign their access level.</p>
                        </div>
                        <button onClick={resetAddForm} className="p-2 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-gray-600 transition-colors"><X size={20} /></button>
                    </div>

                    <form onSubmit={handleAddUser} className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Username *</label>
                                <input
                                    required
                                    value={addForm.username}
                                    onChange={e => setAddForm({ ...addForm, username: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                    placeholder="e.g. rajesh_acc"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Password *</label>
                                <div className="relative">
                                    <input
                                        required
                                        type={showPassword ? 'text' : 'password'}
                                        value={addForm.password}
                                        onChange={e => setAddForm({ ...addForm, password: e.target.value })}
                                        className="w-full px-4 py-2.5 pr-12 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                        placeholder="Min 6 characters"
                                        minLength={6}
                                    />
                                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                                        {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                    </button>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Assign Role *</label>
                                <select
                                    value={addForm.role}
                                    onChange={e => setAddForm({ ...addForm, role: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium bg-white"
                                >
                                    <option value="ADMIN">Administrator — Full Access</option>
                                    <option value="ACCOUNTANT">Accountant — Financial Access</option>
                                    <option value="SALES">Sales Rep — Customer & Product Access</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">First Name</label>
                                <input
                                    value={addForm.first_name}
                                    onChange={e => setAddForm({ ...addForm, first_name: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                    placeholder="Rajesh"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Last Name</label>
                                <input
                                    value={addForm.last_name}
                                    onChange={e => setAddForm({ ...addForm, last_name: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                    placeholder="Kumar"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Email</label>
                                <input
                                    type="email"
                                    value={addForm.email}
                                    onChange={e => setAddForm({ ...addForm, email: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                    placeholder="rajesh@company.com"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Phone</label>
                                <input
                                    value={addForm.phone}
                                    onChange={e => setAddForm({ ...addForm, phone: e.target.value })}
                                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 outline-none font-medium"
                                    placeholder="+91 98765 43210"
                                />
                            </div>
                        </div>

                        {/* Role Description */}
                        <div className="bg-indigo-50/50 border border-indigo-100 rounded-xl p-4">
                            <p className="text-xs font-bold uppercase tracking-wider text-indigo-600 mb-1">Role Permissions Summary</p>
                            <p className="text-sm text-gray-700">{getRoleDescription(addForm.role)}</p>
                        </div>

                        <div className="flex gap-3 justify-end pt-2">
                            <button type="button" onClick={resetAddForm} className="px-5 py-2.5 bg-gray-100 text-gray-700 font-semibold rounded-xl hover:bg-gray-200 transition-colors">
                                Cancel
                            </button>
                            <button
                                type="submit"
                                disabled={addLoading}
                                className={`px-6 py-2.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 ${addLoading ? 'opacity-50 cursor-not-allowed' : 'transform hover:-translate-y-0.5'}`}
                            >
                                {addLoading ? (
                                    <><div className="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white"></div> Creating...</>
                                ) : (
                                    <><UserPlus size={16} /> Create User</>
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            )}

            {/* Users Table */}
            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="overflow-x-auto">
                    {loading ? (
                        <div className="py-20 flex justify-center">
                            <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div>
                        </div>
                    ) : filteredUsers.length === 0 ? (
                        <div className="p-16 text-center">
                            <Shield size={48} className="mx-auto text-gray-300 mb-4" />
                            <h3 className="text-lg font-bold text-gray-900 mb-2">
                                {searchQuery ? 'No users match your search' : 'No users found'}
                            </h3>
                            <p className="text-gray-500 max-w-sm mx-auto">
                                {searchQuery ? 'Try a different search term.' : 'Click "Add User" to create the first team member.'}
                            </p>
                        </div>
                    ) : (
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/80 border-b border-gray-100 uppercase text-xs font-semibold tracking-wider text-gray-500">
                                    <th className="p-4 pl-6">User / Employee</th>
                                    <th className="p-4">Contact Info</th>
                                    <th className="p-4">Assigned Role</th>
                                    <th className="p-4 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {filteredUsers.map((u) => {
                                    const isEditing = editingUserId === u.id;
                                    const isSelf = user?.username === u.username;

                                    return (
                                        <tr key={u.id} className={`hover:bg-gray-50/50 transition-colors group ${isSelf ? 'bg-indigo-50/20' : ''}`}>
                                            <td className="p-4 pl-6">
                                                <div className="flex items-center gap-4">
                                                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold text-lg shadow-inner ${isSelf ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
                                                        {u.first_name ? u.first_name.charAt(0).toUpperCase() : u.username.charAt(0).toUpperCase()}
                                                    </div>
                                                    <div>
                                                        <p className="font-bold text-gray-900 text-lg tracking-tight">
                                                            {u.first_name || u.last_name ? `${u.first_name} ${u.last_name}` : u.username}
                                                            {isSelf && <span className="ml-2 text-[10px] bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full uppercase tracking-wider">You</span>}
                                                        </p>
                                                        <p className="text-xs text-gray-500 font-medium tracking-wide">@{u.username}</p>
                                                    </div>
                                                </div>
                                            </td>

                                            <td className="p-4 space-y-2">
                                                <div className="flex items-center gap-2 text-sm text-gray-600">
                                                    <Mail size={14} className="text-gray-400" />
                                                    {u.email || <span className="text-gray-400 italic">No email</span>}
                                                </div>
                                                <div className="flex items-center gap-2 text-sm text-gray-600">
                                                    <Phone size={14} className="text-gray-400" />
                                                    {u.profile?.phone || <span className="text-gray-400 italic">No phone</span>}
                                                </div>
                                            </td>

                                            <td className="p-4">
                                                {isEditing ? (
                                                    <select
                                                        className="bg-white border border-indigo-300 text-sm rounded-xl focus:ring-indigo-500 focus:border-indigo-500 block w-full p-2.5 outline-none shadow-sm font-medium"
                                                        value={editRole}
                                                        onChange={(e) => setEditRole(e.target.value)}
                                                    >
                                                        <option value="ADMIN">Administrator</option>
                                                        <option value="ACCOUNTANT">Accountant</option>
                                                        <option value="SALES">Sales Rep</option>
                                                    </select>
                                                ) : (
                                                    getRoleBadge(u.profile?.role)
                                                )}
                                            </td>

                                            <td className="p-4">
                                                <div className="flex items-center justify-center gap-2">
                                                    {isEditing ? (
                                                        <>
                                                            <button
                                                                onClick={() => handleUpdateRole(u.id)}
                                                                className="px-4 py-2 bg-indigo-600 text-white text-xs font-bold rounded-lg hover:bg-indigo-700 shadow-sm flex items-center gap-1.5"
                                                            >
                                                                <Save size={14} /> Save
                                                            </button>
                                                            <button
                                                                onClick={cancelEdit}
                                                                className="px-4 py-2 bg-gray-100 text-gray-600 text-xs font-bold rounded-lg hover:bg-gray-200"
                                                            >
                                                                Cancel
                                                            </button>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <button
                                                                onClick={() => startEdit(u)}
                                                                disabled={isSelf}
                                                                className={`p-2 rounded-lg transition-colors ${isSelf ? 'text-gray-300 cursor-not-allowed' : 'text-gray-400 hover:text-indigo-600 hover:bg-indigo-50'}`}
                                                                title={isSelf ? "Cannot edit your own role" : "Edit Role"}
                                                            >
                                                                <Edit2 size={18} />
                                                            </button>
                                                            <button
                                                                onClick={() => handleDeleteUser(u.id, u.username)}
                                                                disabled={isSelf}
                                                                className={`p-2 rounded-lg transition-colors ${isSelf ? 'text-gray-300 cursor-not-allowed' : 'text-gray-400 hover:text-rose-600 hover:bg-rose-50'}`}
                                                                title={isSelf ? "Cannot delete yourself" : "Delete User"}
                                                            >
                                                                <Trash2 size={18} />
                                                            </button>
                                                        </>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>

            {/* Total Users Footer */}
            {!loading && filteredUsers.length > 0 && (
                <div className="text-sm text-gray-500 font-medium text-center">
                    Showing {filteredUsers.length} of {users.length} user(s) • {roleCounts.ADMIN} Admin, {roleCounts.ACCOUNTANT} Accountant, {roleCounts.SALES} Sales
                </div>
            )}
        </div>
    );
};

export default RoleManagement;
