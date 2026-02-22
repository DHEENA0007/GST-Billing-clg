import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import { Clock, User, Search, Filter, Activity, Shield } from 'lucide-react';

const AuditLogs = () => {
    const { token } = useContext(AuthContext);
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [filterAction, setFilterAction] = useState('ALL');

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => { fetchLogs(); }, []);

    const fetchLogs = async () => {
        try {
            const res = await axios.get('/api/audit-logs/', hdrs);
            setLogs(res.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };

    const getActionColor = (action) => {
        if (action.includes('CREATE') || action.includes('ADD')) return 'bg-emerald-50 text-emerald-600 border-emerald-100';
        if (action.includes('UPDATE') || action.includes('EDIT')) return 'bg-blue-50 text-blue-600 border-blue-100';
        if (action.includes('DELETE') || action.includes('CANCEL')) return 'bg-rose-50 text-rose-600 border-rose-100';
        return 'bg-gray-50 text-gray-600 border-gray-100';
    };

    const allActions = [...new Set(logs.map(l => l.action))];

    const filtered = logs.filter(l => {
        const matchAction = filterAction === 'ALL' || l.action === filterAction;
        const q = searchQuery.toLowerCase();
        const matchSearch = (l.action || '').toLowerCase().includes(q) ||
            (l.details || '').toLowerCase().includes(q) ||
            (l.user_name || '').toLowerCase().includes(q);
        return matchAction && matchSearch;
    });

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <Shield className="text-indigo-600" size={28} />
                        Audit Trail
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-10">Track all actions performed across the system for compliance.</p>
                </div>
            </div>

            {/* Filters */}
            <div className="flex flex-wrap gap-3 items-center">
                <div className="relative flex-1 max-w-xs">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input type="text" value={searchQuery} onChange={e => setSearchQuery(e.target.value)} placeholder="Search logs..."
                        className="w-full bg-white border border-gray-200 text-sm rounded-xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all font-medium shadow-sm" />
                </div>
                {allActions.length > 0 && (
                    <select value={filterAction} onChange={e => setFilterAction(e.target.value)}
                        className="bg-white border border-gray-200 text-sm rounded-xl px-4 py-2.5 outline-none font-medium shadow-sm">
                        <option value="ALL">All Actions</option>
                        {allActions.map(a => <option key={a} value={a}>{a}</option>)}
                    </select>
                )}
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="py-20 flex justify-center"><div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-600"></div></div>
                ) : filtered.length === 0 ? (
                    <div className="p-16 text-center">
                        <Activity size={48} className="mx-auto text-gray-300 mb-4" />
                        <h3 className="text-lg font-bold text-gray-900 mb-2">No audit logs</h3>
                        <p className="text-gray-500">System actions will be recorded here automatically.</p>
                    </div>
                ) : (
                    <div className="divide-y divide-gray-50">
                        {filtered.map(log => (
                            <div key={log.id} className="flex items-start gap-4 p-5 hover:bg-gray-50/50 transition-colors">
                                <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600 font-bold text-sm shrink-0 mt-0.5">
                                    {(log.user_name || 'S').charAt(0).toUpperCase()}
                                </div>
                                <div className="flex-1">
                                    <div className="flex items-center gap-3 flex-wrap">
                                        <span className="font-bold text-gray-900">{log.user_name || 'System'}</span>
                                        <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider border ${getActionColor(log.action)}`}>{log.action}</span>
                                    </div>
                                    <p className="text-sm text-gray-600 mt-1">{log.details}</p>
                                    <div className="flex items-center gap-4 mt-2 text-xs text-gray-400">
                                        <span className="flex items-center gap-1"><Clock size={12} /> {new Date(log.timestamp).toLocaleString('en-IN')}</span>
                                        {log.ip_address && <span>IP: {log.ip_address}</span>}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {!loading && <p className="text-sm text-gray-500 text-center font-medium">Showing {filtered.length} of {logs.length} log entries</p>}
        </div>
    );
};

export default AuditLogs;
