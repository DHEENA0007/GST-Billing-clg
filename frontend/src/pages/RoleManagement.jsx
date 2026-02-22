import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Shield, ShieldAlert, UserCheck, Search, Trash2, Edit2, ShieldCheck, Mail, Phone, Briefcase } from 'lucide-react';

const RoleManagement = () => {
    const { token, user } = useContext(AuthContext);
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Edit State
    const [editingUserId, setEditingUserId] = useState(null);
    const [editRole, setEditRole] = useState('');

    const API_URL = '/api/roles/';

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const res = await axios.get(API_URL, {
                headers: { Authorization: `Bearer ${token}` }
            });
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

    const startEdit = (user) => {
        setEditingUserId(user.id);
        setEditRole(user.profile?.role || 'SALES');
    };

    const cancelEdit = () => {
        setEditingUserId(null);
        setEditRole('');
    };

    const handleUpdateRole = async (userId) => {
        try {
            await axios.patch(`${API_URL}${userId}/`,
                { role: editRole },
                { headers: { Authorization: `Bearer ${token}` } }
            );

            // Update local state
            setUsers(users.map(u => {
                if (u.id === userId) {
                    return { ...u, profile: { ...u.profile, role: editRole } };
                }
                return u;
            }));
            cancelEdit();
        } catch (err) {
            alert(err.response?.data?.detail || 'Failed to update role');
        }
    };

    const handleDeleteUser = async (userId, username) => {
        if (!window.confirm(`Are you sure you want to delete user "${username}"? This cannot be undone.`)) {
            return;
        }

        try {
            await axios.delete(`${API_URL}${userId}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUsers(users.filter(u => u.id !== userId));
        } catch (err) {
            alert(err.response?.data?.detail || 'Failed to delete user');
        }
    };

    const getRoleBadge = (role) => {
        switch (role) {
            case 'ADMIN':
                return <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-rose-50 text-rose-600 border border-rose-100"><ShieldAlert size={12} /> Admin</span>;
            case 'ACCOUNTANT':
                return <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-purple-50 text-purple-600 border border-purple-100"><Briefcase size={12} /> Accountant</span>;
            case 'SALES':
            default:
                return <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-emerald-50 text-emerald-600 border border-emerald-100"><UserCheck size={12} /> Sales</span>;
        }
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
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <ShieldCheck className="text-indigo-600" size={28} />
                        Role & Access Management
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Control who has access to specific modules within the GST Billing suite.</p>
                </div>
                <div className="flex gap-3">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            placeholder="Search users..."
                            className="w-64 bg-white border border-gray-200 text-sm rounded-xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all font-medium text-gray-900 shadow-sm"
                        />
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="overflow-x-auto">
                    {loading ? (
                        <div className="py-20 flex justify-center">
                            <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div>
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
                                {users.map((u) => {
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
                                                    {u.email || <span className="text-gray-400 italic">No email provided</span>}
                                                </div>
                                                <div className="flex items-center gap-2 text-sm text-gray-600">
                                                    <Phone size={14} className="text-gray-400" />
                                                    {u.profile?.phone || <span className="text-gray-400 italic">No phone provided</span>}
                                                </div>
                                            </td>

                                            <td className="p-4">
                                                {isEditing ? (
                                                    <div className="flex items-center gap-2">
                                                        <select
                                                            className="bg-white border border-gray-300 text-sm rounded-lg focus:ring-indigo-500 focus:border-indigo-500 block w-full p-2 outline-none shadow-sm"
                                                            value={editRole}
                                                            onChange={(e) => setEditRole(e.target.value)}
                                                        >
                                                            <option value="ADMIN">Administrator</option>
                                                            <option value="ACCOUNTANT">Accountant</option>
                                                            <option value="SALES">Sales Rep</option>
                                                        </select>
                                                    </div>
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
                                                                className="px-3 py-1.5 bg-indigo-600 text-white text-xs font-bold rounded-lg hover:bg-indigo-700 shadow-sm"
                                                            >
                                                                Save
                                                            </button>
                                                            <button
                                                                onClick={cancelEdit}
                                                                className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs font-bold rounded-lg hover:bg-gray-200"
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
        </div>
    );
};

export default RoleManagement;
