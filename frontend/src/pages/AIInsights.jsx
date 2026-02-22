import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import AuthContext from '../context/AuthContext';
import {
    Brain, AlertTriangle, Lightbulb, TrendingUp, Activity,
    ShieldAlert, Bell, Zap, Package, Users, DollarSign,
    ArrowUpRight, ArrowDownRight, ChevronRight, Sparkles,
    BarChart3, Target, RefreshCw, Archive, Crown, UserX, FileText
} from 'lucide-react';

const AIInsights = () => {
    const { token } = useContext(AuthContext);
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeSection, setActiveSection] = useState('overview');
    const [refreshing, setRefreshing] = useState(false);

    const hdrs = { headers: { Authorization: `Bearer ${token}` } };
    const fmt = (v) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(v || 0);

    useEffect(() => { fetchAIData(); }, []);

    const fetchAIData = async () => {
        try {
            const res = await axios.get('/api/ai/dashboard/', hdrs);
            setData(res.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); setRefreshing(false); }
    };

    const handleRefresh = () => { setRefreshing(true); fetchAIData(); };

    const severityConfig = {
        CRITICAL: { bg: 'bg-rose-50', border: 'border-rose-200', text: 'text-rose-700', badge: 'bg-rose-100 text-rose-700', icon: <ShieldAlert size={18} className="text-rose-500" /> },
        WARNING: { bg: 'bg-amber-50', border: 'border-amber-200', text: 'text-amber-700', badge: 'bg-amber-100 text-amber-700', icon: <AlertTriangle size={18} className="text-amber-500" /> },
        INFO: { bg: 'bg-blue-50', border: 'border-blue-200', text: 'text-blue-700', badge: 'bg-blue-100 text-blue-700', icon: <Bell size={18} className="text-blue-500" /> },
    };

    const impactColors = { HIGH: 'text-rose-600 bg-rose-50', MEDIUM: 'text-amber-600 bg-amber-50', LOW: 'text-blue-600 bg-blue-50' };

    const iconMap = {
        'package': <Package size={20} className="text-indigo-600" />,
        'archive': <Archive size={20} className="text-amber-600" />,
        'crown': <Crown size={20} className="text-yellow-600" />,
        'user-x': <UserX size={20} className="text-gray-600" />,
        'trending-up': <TrendingUp size={20} className="text-emerald-600" />,
        'file-text': <FileText size={20} className="text-blue-600" />,
        'alert-triangle': <AlertTriangle size={20} className="text-amber-600" />,
    };

    if (loading) {
        return (
            <div className="min-h-[600px] flex flex-col items-center justify-center gap-4">
                <div className="relative">
                    <div className="w-16 h-16 rounded-full border-4 border-indigo-100 border-t-indigo-600 animate-spin"></div>
                    <Brain size={24} className="text-indigo-600 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
                </div>
                <p className="text-gray-500 font-medium animate-pulse">AI Engine analyzing your business data...</p>
            </div>
        );
    }

    const alerts = data?.alerts || [];
    const recs = data?.recommendations || [];
    const predictions = data?.predictions || {};
    const healthScore = predictions?.business_health_score || { score: 0, grade: '-', factors: [] };
    const forecast = predictions?.revenue_forecast || {};
    const demandForecast = predictions?.demand_forecast || [];

    const criticalCount = alerts.filter(a => a.severity === 'CRITICAL').length;
    const warningCount = alerts.filter(a => a.severity === 'WARNING').length;

    const getScoreColor = (score) => {
        if (score >= 80) return 'text-emerald-600';
        if (score >= 60) return 'text-amber-600';
        return 'text-rose-600';
    };

    const getScoreGradient = (score) => {
        if (score >= 80) return 'from-emerald-500 to-teal-500';
        if (score >= 60) return 'from-amber-500 to-orange-500';
        return 'from-rose-500 to-pink-500';
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-3">
                        <div className="p-2 bg-gradient-to-tr from-violet-600 to-indigo-600 rounded-xl text-white shadow-lg shadow-indigo-500/30">
                            <Brain size={24} />
                        </div>
                        AI Intelligence Center
                    </h2>
                    <p className="text-gray-500 mt-1 font-medium ml-12">Real-time AI-powered insights, predictions, and alerts for your business.</p>
                </div>
                <button onClick={handleRefresh} className={`flex items-center gap-2 px-5 py-2.5 bg-white border border-gray-200 text-gray-700 font-semibold rounded-xl hover:bg-gray-50 shadow-sm transition-all ${refreshing ? 'opacity-50 cursor-not-allowed' : ''}`}>
                    <RefreshCw size={16} className={refreshing ? 'animate-spin' : ''} /> Refresh
                </button>
            </div>

            {/* Key Metrics Row */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                {/* Health Score */}
                <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 relative overflow-hidden group hover:shadow-lg transition-all">
                    <div className={`absolute -right-6 -bottom-6 w-32 h-32 rounded-full bg-gradient-to-tr ${getScoreGradient(healthScore.score)} opacity-10 group-hover:scale-150 transition-transform duration-500`}></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-gray-500 text-sm font-medium mb-3">
                            <Activity size={16} /> Business Health
                        </div>
                        <div className="flex items-end gap-3">
                            <span className={`text-5xl font-black tracking-tighter ${getScoreColor(healthScore.score)}`}>{healthScore.score}</span>
                            <span className={`text-2xl font-bold ${getScoreColor(healthScore.score)} mb-1`}>/100</span>
                        </div>
                        <div className="mt-3 w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                            <div className={`h-full bg-gradient-to-r ${getScoreGradient(healthScore.score)} rounded-full transition-all duration-1000`} style={{ width: `${healthScore.score}%` }}></div>
                        </div>
                        <p className="text-xs text-gray-500 mt-2 font-medium">Grade: <span className={`font-bold ${getScoreColor(healthScore.score)}`}>{healthScore.grade}</span></p>
                    </div>
                </div>

                {/* Alerts Summary */}
                <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 relative overflow-hidden group hover:shadow-lg transition-all">
                    <div className="absolute -right-6 -bottom-6 w-32 h-32 rounded-full bg-rose-500 opacity-5 group-hover:scale-150 transition-transform duration-500"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-gray-500 text-sm font-medium mb-3">
                            <AlertTriangle size={16} /> Active Alerts
                        </div>
                        <span className="text-5xl font-black tracking-tighter text-gray-900">{alerts.length}</span>
                        <div className="flex gap-3 mt-3">
                            {criticalCount > 0 && <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-rose-100 text-rose-700">{criticalCount} Critical</span>}
                            {warningCount > 0 && <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-700">{warningCount} Warning</span>}
                        </div>
                    </div>
                </div>

                {/* Revenue Forecast */}
                <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 relative overflow-hidden group hover:shadow-lg transition-all">
                    <div className="absolute -right-6 -bottom-6 w-32 h-32 rounded-full bg-emerald-500 opacity-5 group-hover:scale-150 transition-transform duration-500"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-gray-500 text-sm font-medium mb-3">
                            <TrendingUp size={16} /> Revenue Forecast
                        </div>
                        <span className="text-3xl font-black tracking-tighter text-gray-900">{fmt(forecast.forecast)}</span>
                        <div className="flex items-center gap-2 mt-3">
                            {forecast.trend === 'GROWING' ? (
                                <span className="flex items-center gap-1 text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full"><ArrowUpRight size={12} /> Growing {forecast.trend_percentage}%</span>
                            ) : forecast.trend === 'DECLINING' ? (
                                <span className="flex items-center gap-1 text-xs font-bold text-rose-600 bg-rose-50 px-2 py-0.5 rounded-full"><ArrowDownRight size={12} /> Declining {Math.abs(forecast.trend_percentage)}%</span>
                            ) : (
                                <span className="text-xs font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">Stable</span>
                            )}
                            <span className="text-xs text-gray-400">{forecast.confidence}% confidence</span>
                        </div>
                    </div>
                </div>

                {/* Recommendations */}
                <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 relative overflow-hidden group hover:shadow-lg transition-all">
                    <div className="absolute -right-6 -bottom-6 w-32 h-32 rounded-full bg-violet-500 opacity-5 group-hover:scale-150 transition-transform duration-500"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-gray-500 text-sm font-medium mb-3">
                            <Lightbulb size={16} /> Recommendations
                        </div>
                        <span className="text-5xl font-black tracking-tighter text-gray-900">{recs.length}</span>
                        <p className="text-xs text-gray-500 mt-3 font-medium">AI-powered suggestions to grow your business</p>
                    </div>
                </div>
            </div>

            {/* Section Tabs */}
            <div className="flex gap-2">
                {[
                    { id: 'overview', label: 'Health Factors', icon: <Activity size={15} /> },
                    { id: 'alerts', label: `Alerts (${alerts.length})`, icon: <AlertTriangle size={15} /> },
                    { id: 'recommendations', label: 'Recommendations', icon: <Lightbulb size={15} /> },
                    { id: 'predictions', label: 'Predictions', icon: <TrendingUp size={15} /> },
                ].map(tab => (
                    <button key={tab.id} onClick={() => setActiveSection(tab.id)}
                        className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all ${activeSection === tab.id
                            ? 'bg-gradient-to-r from-violet-600 to-indigo-600 text-white shadow-lg shadow-indigo-600/20'
                            : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
                            }`}>
                        {tab.icon} {tab.label}
                    </button>
                ))}
            </div>

            {/* Dynamic Content */}
            <div className="min-h-[400px]">
                {/* Section: Health Factors */}
                {activeSection === 'overview' && (
                    <div className="space-y-6 animate-in fade-in duration-300">
                        <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                            <h3 className="text-lg font-bold text-gray-900 mb-2 flex items-center gap-2"><Target size={20} className="text-indigo-600" /> Business Health Breakdown</h3>
                            <p className="text-sm text-gray-500 mb-6">{healthScore.summary}</p>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                {healthScore.factors.map((f, i) => (
                                    <div key={i} className="bg-gray-50/80 rounded-2xl p-5 border border-gray-100">
                                        <div className="flex justify-between items-center mb-3">
                                            <span className="font-bold text-gray-900">{f.name}</span>
                                            <span className={`text-sm font-bold ${f.score / f.max >= 0.8 ? 'text-emerald-600' : f.score / f.max >= 0.5 ? 'text-amber-600' : 'text-rose-600'}`}>{f.score}/{f.max}</span>
                                        </div>
                                        <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
                                            <div className={`h-full rounded-full transition-all duration-700 ${f.score / f.max >= 0.8 ? 'bg-emerald-500' : f.score / f.max >= 0.5 ? 'bg-amber-500' : 'bg-rose-500'}`} style={{ width: `${(f.score / f.max) * 100}%` }}></div>
                                        </div>
                                        <p className="text-xs text-gray-500 mt-2 font-medium">{f.detail}</p>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Revenue Trend Chart (visual) */}
                        {forecast.monthly_data && forecast.monthly_data.length > 0 && (
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><BarChart3 size={20} className="text-indigo-600" /> Revenue Trend (6 Months)</h3>
                                <div className="flex items-end gap-4 h-48">
                                    {forecast.monthly_data.map((m, i) => {
                                        const maxRev = Math.max(...forecast.monthly_data.map(d => d.revenue), 1);
                                        const height = (m.revenue / maxRev) * 100;
                                        return (
                                            <div key={i} className="flex-1 flex flex-col items-center gap-2">
                                                <span className="text-xs font-bold text-gray-900">{fmt(m.revenue)}</span>
                                                <div className="w-full rounded-t-xl bg-gradient-to-t from-indigo-600 to-violet-500 transition-all duration-700 hover:from-indigo-500 hover:to-violet-400 shadow-lg shadow-indigo-500/10" style={{ height: `${Math.max(height, 4)}%` }}></div>
                                                <span className="text-xs text-gray-500 font-medium">{m.month}</span>
                                            </div>
                                        );
                                    })}
                                    {/* Forecast bar */}
                                    <div className="flex-1 flex flex-col items-center gap-2">
                                        <span className="text-xs font-bold text-emerald-600">{fmt(forecast.forecast)}</span>
                                        <div className="w-full rounded-t-xl bg-gradient-to-t from-emerald-500 to-teal-400 transition-all duration-700 border-2 border-dashed border-emerald-300 shadow-lg shadow-emerald-500/10" style={{ height: `${Math.max((forecast.forecast / Math.max(...forecast.monthly_data.map(d => d.revenue), 1)) * 100, 4)}%` }}></div>
                                        <span className="text-xs text-emerald-600 font-bold">Forecast</span>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                )}

                {/* Section: Alerts */}
                {activeSection === 'alerts' && (
                    <div className="space-y-4 animate-in fade-in duration-300">
                        {alerts.length === 0 ? (
                            <div className="bg-white rounded-3xl p-16 text-center shadow-sm border border-gray-100">
                                <Sparkles size={48} className="mx-auto text-emerald-400 mb-4" />
                                <h3 className="text-lg font-bold text-gray-900 mb-2">All Clear!</h3>
                                <p className="text-gray-500">No alerts at the moment. Your business is running smoothly.</p>
                            </div>
                        ) : alerts.map((alert, i) => {
                            const cfg = severityConfig[alert.severity] || severityConfig.INFO;
                            return (
                                <div key={i} className={`${cfg.bg} rounded-2xl p-5 border ${cfg.border} hover:shadow-md transition-all`}>
                                    <div className="flex items-start gap-4">
                                        <div className="mt-0.5">{cfg.icon}</div>
                                        <div className="flex-1">
                                            <div className="flex items-center gap-3 mb-1">
                                                <h4 className={`font-bold ${cfg.text}`}>{alert.title}</h4>
                                                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${cfg.badge}`}>{alert.severity}</span>
                                            </div>
                                            <p className="text-sm text-gray-700">{alert.message}</p>
                                            <div className="flex items-center gap-2 mt-3">
                                                <Zap size={13} className="text-indigo-500" />
                                                <span className="text-xs font-semibold text-indigo-600">{alert.action}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}

                {/* Section: Recommendations */}
                {activeSection === 'recommendations' && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-5 animate-in fade-in duration-300">
                        {recs.length === 0 ? (
                            <div className="md:col-span-2 bg-white rounded-3xl p-16 text-center shadow-sm border border-gray-100">
                                <Lightbulb size={48} className="mx-auto text-gray-300 mb-4" />
                                <h3 className="text-lg font-bold text-gray-900 mb-2">No Recommendations Yet</h3>
                                <p className="text-gray-500">Add more data (customers, products, invoices) for AI to generate suggestions.</p>
                            </div>
                        ) : recs.map((rec, i) => (
                            <div key={i} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-all group relative overflow-hidden">
                                <div className="absolute top-0 right-0 w-24 h-24 bg-violet-500/5 rounded-bl-full group-hover:scale-150 transition-transform duration-500"></div>
                                <div className="relative z-10">
                                    <div className="flex items-center justify-between mb-3">
                                        <div className="flex items-center gap-2">
                                            <div className="w-9 h-9 rounded-xl bg-indigo-50 flex items-center justify-center">
                                                {iconMap[rec.icon] || <Lightbulb size={20} className="text-indigo-600" />}
                                            </div>
                                            <span className="text-xs font-bold uppercase tracking-wider text-gray-400">{rec.category}</span>
                                        </div>
                                        <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${impactColors[rec.impact]}`}>{rec.impact} Impact</span>
                                    </div>
                                    <h4 className="font-bold text-gray-900 mb-2">{rec.title}</h4>
                                    <p className="text-sm text-gray-600 leading-relaxed">{rec.message}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Section: Predictions */}
                {activeSection === 'predictions' && (
                    <div className="space-y-6 animate-in fade-in duration-300">
                        {/* Demand Forecasts */}
                        {demandForecast.length > 0 && (
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Package size={20} className="text-indigo-600" /> Product Demand Forecast</h3>
                                <div className="overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead><tr className="bg-gray-50 border-b text-xs uppercase text-gray-500 font-semibold tracking-wider">
                                            <th className="p-4 pl-6">Product</th>
                                            <th className="p-4">Last 3 Months</th>
                                            <th className="p-4">Predicted/Month</th>
                                            <th className="p-4">Trend</th>
                                            <th className="p-4">Stock</th>
                                            <th className="p-4">Weeks Left</th>
                                        </tr></thead>
                                        <tbody className="divide-y divide-gray-50">
                                            {demandForecast.map((df, i) => (
                                                <tr key={i} className="hover:bg-gray-50/50">
                                                    <td className="p-4 pl-6 font-bold text-gray-900">{df.product}</td>
                                                    <td className="p-4 text-sm text-gray-600">{df.monthly_sales.join(' → ')}</td>
                                                    <td className="p-4 font-bold text-indigo-600">{df.predicted_demand} units</td>
                                                    <td className="p-4">
                                                        <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold ${df.trend === 'UP' ? 'bg-emerald-50 text-emerald-600' :
                                                            df.trend === 'DOWN' ? 'bg-rose-50 text-rose-600' : 'bg-gray-100 text-gray-600'
                                                            }`}>
                                                            {df.trend === 'UP' ? <ArrowUpRight size={12} /> : df.trend === 'DOWN' ? <ArrowDownRight size={12} /> : null}
                                                            {df.trend}
                                                        </span>
                                                    </td>
                                                    <td className="p-4 font-medium">{df.current_stock} units</td>
                                                    <td className="p-4">
                                                        <span className={`font-bold ${df.reorder_urgent ? 'text-rose-600' : df.weeks_of_stock < 4 ? 'text-amber-600' : 'text-emerald-600'}`}>
                                                            {df.weeks_of_stock} weeks
                                                            {df.reorder_urgent && <span className="ml-1 text-[10px] uppercase bg-rose-100 text-rose-700 px-1.5 py-0.5 rounded-full font-bold">REORDER</span>}
                                                        </span>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}

                        {/* Payment Delay Predictions */}
                        {predictions.payment_prediction && predictions.payment_prediction.length > 0 && (
                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-gray-100">
                                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2"><Users size={20} className="text-indigo-600" /> Customer Payment Behavior</h3>
                                <div className="space-y-3">
                                    {predictions.payment_prediction.map((pp, i) => (
                                        <div key={i} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center font-bold text-indigo-600 text-sm">
                                                    {pp.customer.charAt(0)}
                                                </div>
                                                <div>
                                                    <p className="font-bold text-gray-900">{pp.customer}</p>
                                                    <p className="text-xs text-gray-500">Based on {pp.sample_size} invoice(s)</p>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-4">
                                                <div className="text-right">
                                                    <p className="text-sm text-gray-500">Avg. Delay</p>
                                                    <p className={`font-bold ${pp.avg_delay_days > 15 ? 'text-rose-600' : pp.avg_delay_days > 5 ? 'text-amber-600' : 'text-emerald-600'}`}>{pp.avg_delay_days} days</p>
                                                </div>
                                                <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${pp.risk_level === 'HIGH' ? 'bg-rose-100 text-rose-700' :
                                                    pp.risk_level === 'MEDIUM' ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'
                                                    }`}>{pp.risk_level} Risk</span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {demandForecast.length === 0 && (!predictions.payment_prediction || predictions.payment_prediction.length === 0) && (
                            <div className="bg-white rounded-3xl p-16 text-center shadow-sm border border-gray-100">
                                <TrendingUp size={48} className="mx-auto text-gray-300 mb-4" />
                                <h3 className="text-lg font-bold text-gray-900 mb-2">Need More Data</h3>
                                <p className="text-gray-500">Add invoices and payments so the AI can learn patterns and generate predictions.</p>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

export default AIInsights;
