import React, { useState, useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AuthContext from '../context/AuthContext';
import { Hexagon, Lock, EyeOff, Eye, User, ArrowRight } from 'lucide-react';

const Login = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useContext(AuthContext);
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        const result = await login(username, password);
        setLoading(false);
        if (result.success) {
            navigate('/');
        } else {
            setError(result.message || 'Invalid credentials');
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC] relative overflow-hidden">
            {/* Decorative gradient backgrounds */}
            <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-indigo-500 rounded-full mix-blend-multiply filter blur-[100px] opacity-20 animate-blob"></div>
            <div className="absolute top-[20%] right-[-10%] w-[40%] h-[40%] bg-purple-500 rounded-full mix-blend-multiply filter blur-[100px] opacity-20 animate-blob animation-delay-2000"></div>
            <div className="absolute bottom-[-10%] left-[20%] w-[40%] h-[40%] bg-emerald-500 rounded-full mix-blend-multiply filter blur-[100px] opacity-20 animate-blob animation-delay-4000"></div>

            <div className="w-full max-w-md p-8 relative z-10">
                <div className="bg-white/80 backdrop-blur-xl border border-white shadow-2xl rounded-3xl p-10 transform hover:-translate-y-1 transition-all duration-300">
                    <div className="flex justify-center mb-8">
                        <div className="bg-gradient-to-tr from-indigo-600 to-purple-600 p-3 rounded-2xl shadow-lg shadow-indigo-600/30">
                            <Hexagon size={32} className="text-white fill-white/20" />
                        </div>
                    </div>

                    <h2 className="text-3xl font-bold text-center text-gray-900 tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 mb-2">
                        Welcome Back
                    </h2>
                    <p className="text-center text-gray-500 mb-8 font-medium">Log in to manage your GST billing</p>

                    {error && (
                        <div className="mb-6 p-4 bg-rose-50 border border-rose-100 text-rose-600 text-sm font-semibold rounded-xl flex items-center justify-center animate-in slide-in-from-top-2">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleLogin} className="space-y-5">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">Username</label>
                            <div className="relative group">
                                <User size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                <input
                                    type="text"
                                    required
                                    placeholder="admin"
                                    className="w-full pl-11 pr-4 py-3 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition-all text-gray-900 font-medium placeholder:text-gray-400 outline-none hover:bg-white"
                                    value={username}
                                    onChange={(e) => setUsername(e.target.value)}
                                />
                            </div>
                        </div>

                        <div>
                            <div className="flex justify-between items-center mb-2">
                                <label className="block text-sm font-bold text-gray-700">Password</label>
                                <a href="#" className="text-sm font-semibold text-indigo-600 hover:text-indigo-700">Forgot?</a>
                            </div>
                            <div className="relative group">
                                <Lock size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    required
                                    placeholder="••••••••"
                                    className="w-full pl-11 pr-12 py-3 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition-all text-gray-900 font-medium placeholder:text-gray-400 outline-none hover:bg-white"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className={`w-full py-3.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all flex items-center justify-center gap-2 group mt-8 ${loading ? 'opacity-70 cursor-not-allowed' : 'transform hover:-translate-y-0.5'}`}
                        >
                            {loading ? 'Authenticating...' : 'Sign In'}
                            {!loading && <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />}
                        </button>
                    </form>

                    <p className="mt-8 text-center text-sm text-gray-500 font-medium">
                        Don't have an account?{' '}
                        <Link to="/register" className="font-bold text-indigo-600 hover:text-indigo-700">
                            Create an account
                        </Link>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default Login;
