import React, { useState, useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AuthContext from '../context/AuthContext';
import { Hexagon, Lock, User, Mail, Briefcase, Phone, ArrowRight, Eye, EyeOff } from 'lucide-react';

const Register = () => {
    const [formData, setFormData] = useState({
        username: '', email: '', password: '', role: 'SALES', phone: ''
    });
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { register } = useContext(AuthContext);
    const navigate = useNavigate();

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleRegister = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        const result = await register(formData);
        setLoading(false);
        if (result.success) {
            navigate('/');
        } else {
            setError(result.message || 'Registration failed');
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC] relative overflow-hidden py-12">
            {/* Decorative gradient backgrounds */}
            <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-indigo-500 rounded-full mix-blend-multiply filter blur-[100px] opacity-20 animate-blob"></div>
            <div className="absolute top-[20%] right-[-10%] w-[40%] h-[40%] bg-purple-500 rounded-full mix-blend-multiply filter blur-[100px] opacity-20 animate-blob animation-delay-2000"></div>

            <div className="w-full max-w-lg p-6 relative z-10">
                <div className="bg-white/80 backdrop-blur-xl border border-white shadow-2xl rounded-3xl p-10 transform transition-all duration-300">
                    <div className="flex justify-center mb-6">
                        <div className="bg-gradient-to-tr from-indigo-600 to-purple-600 p-3 rounded-2xl shadow-lg shadow-indigo-600/30">
                            <Hexagon size={32} className="text-white fill-white/20" />
                        </div>
                    </div>

                    <h2 className="text-3xl font-bold text-center text-gray-900 tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 mb-2">
                        Create Account
                    </h2>
                    <p className="text-center text-gray-500 mb-8 font-medium">Join us to manage GST billing seamlessly</p>

                    {error && (
                        <div className="mb-6 p-4 bg-rose-50 border border-rose-100 text-rose-600 text-sm font-semibold rounded-xl flex items-center justify-center animate-in slide-in-from-top-2">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleRegister} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Username <span className="text-rose-500">*</span></label>
                                <div className="relative group">
                                    <User size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                    <input
                                        name="username" type="text" required placeholder="johndoe"
                                        className="w-full pl-10 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 text-sm font-medium transition-all text-gray-900 placeholder:text-gray-400 outline-none hover:bg-white"
                                        onChange={handleChange}
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-1.5">Role</label>
                                <div className="relative group">
                                    <Briefcase size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                    <select
                                        name="role"
                                        className="w-full pl-10 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 text-sm font-medium transition-all text-gray-900 outline-none hover:bg-white appearance-none"
                                        onChange={handleChange}
                                        value={formData.role}
                                    >
                                        <option value="ADMIN">Admin</option>
                                        <option value="ACCOUNTANT">Accountant</option>
                                        <option value="SALES">Sales Rep</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Email</label>
                            <div className="relative group">
                                <Mail size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                <input
                                    name="email" type="email" placeholder="john@company.com"
                                    className="w-full pl-10 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 text-sm font-medium transition-all text-gray-900 placeholder:text-gray-400 outline-none hover:bg-white"
                                    onChange={handleChange}
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Phone</label>
                            <div className="relative group">
                                <Phone size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                <input
                                    name="phone" type="text" placeholder="+91 98765 43210"
                                    className="w-full pl-10 pr-4 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 text-sm font-medium transition-all text-gray-900 placeholder:text-gray-400 outline-none hover:bg-white"
                                    onChange={handleChange}
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-1.5">Password <span className="text-rose-500">*</span></label>
                            <div className="relative group">
                                <Lock size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                <input
                                    name="password" type={showPassword ? 'text' : 'password'} required placeholder="••••••••"
                                    className="w-full pl-10 pr-12 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 text-sm font-medium transition-all text-gray-900 placeholder:text-gray-400 outline-none hover:bg-white"
                                    onChange={handleChange}
                                />
                                <button
                                    type="button"
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className={`w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-lg shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all flex items-center justify-center gap-2 group mt-6 ${loading ? 'opacity-70 cursor-not-allowed' : 'transform hover:-translate-y-0.5'}`}
                        >
                            {loading ? 'Creating Account...' : 'Sign Up'}
                            {!loading && <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />}
                        </button>
                    </form>

                    <p className="mt-8 text-center text-sm text-gray-500 font-medium">
                        Already have an account?{' '}
                        <Link to="/login" className="font-bold text-indigo-600 hover:text-indigo-700">
                            Sign in
                        </Link>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default Register;
