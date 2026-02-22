import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
    Shield, Zap, PieChart, Users, ArrowRight, CheckCircle2,
    Menu, X, Sparkles, Brain, FileText, Layout as LayoutIcon,
    Lock, Globe, ChevronRight, TrendingUp
} from 'lucide-react';

const Landing = () => {
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [scrolled, setScrolled] = useState(false);

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    const features = [
        {
            icon: <FileText className="text-indigo-600" />,
            title: "GST Invoicing",
            description: "Create professional GST invoices instantly. Automatically calculate CGST, SGST, and IGST with precise accuracy."
        },
        {
            icon: <Zap className="text-amber-500" />,
            title: "Smart Insights",
            description: "Get clear insights into your business growth, revenue trends, and tax liabilities through our simple dashboard."
        },
        {
            icon: <PieChart className="text-emerald-600" />,
            title: "Business Reports",
            description: "Generate detailed GSTR-1 and GSTR-3B ready reports. Stay compliant and audit-ready with a single click."
        },
        {
            icon: <Users className="text-blue-600" />,
            title: "Customer Management",
            description: "Track all your client details, history, and outstanding payments in one central, easy-to-manage location."
        },
        {
            icon: <LayoutIcon className="text-purple-600" />,
            title: "Inventory Tracking",
            description: "Keep stock of your products and services. Get notified when items are low and manage your catalog efficiently."
        },
        {
            icon: <Lock className="text-rose-600" />,
            title: "Secure & Reliable",
            description: "Your business data is stored securely with role-based access control, ensuring only authorized people have access."
        }
    ];

    return (
        <div className="min-h-screen bg-slate-50 font-outfit text-slate-900 selection:bg-indigo-100 selection:text-indigo-900">

            {/* Navigation */}
            <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? 'bg-white/90 backdrop-blur-md border-b border-slate-200 py-3 shadow-sm' : 'bg-transparent py-5'
                }`}>
                <div className="container mx-auto px-6 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="bg-indigo-600 p-2 rounded-lg text-white shadow-md">
                            <Sparkles size={20} />
                        </div>
                        <span className="text-xl font-bold tracking-tight font-space text-slate-900 uppercase">
                            GST<span className="text-indigo-600">.</span>EDGE
                        </span>
                    </div>

                    <div className="hidden md:flex items-center gap-8">
                        {['Features', 'About', 'Pricing'].map(item => (
                            <a key={item} href={`#${item.toLowerCase()}`} className="text-sm font-semibold text-slate-500 hover:text-indigo-600 transition-colors">
                                {item}
                            </a>
                        ))}
                    </div>

                    <div className="hidden md:flex items-center gap-4">
                        <Link to="/login" className="text-sm font-bold text-slate-600 hover:text-indigo-600 px-4 py-2">
                            Sign In
                        </Link>
                        <Link to="/register" className="bg-indigo-600 text-white text-sm font-bold px-6 py-2.5 rounded-lg hover:bg-indigo-700 shadow-sm transition-all">
                            Try for Free
                        </Link>
                    </div>

                    <button className="md:hidden p-2 text-slate-600" onClick={() => setIsMenuOpen(!isMenuOpen)}>
                        {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>
                </div>

                {/* Mobile Menu */}
                {isMenuOpen && (
                    <div className="md:hidden absolute top-full left-0 right-0 bg-white border-b border-slate-200 p-6 shadow-xl">
                        <div className="flex flex-col gap-4">
                            {['Features', 'About', 'Pricing'].map(item => (
                                <a key={item} href={`#${item.toLowerCase()}`} className="text-lg font-semibold text-slate-600" onClick={() => setIsMenuOpen(false)}>
                                    {item}
                                </a>
                            ))}
                            <hr className="border-slate-100" />
                            <Link to="/login" className="text-lg font-bold text-indigo-600">Sign In</Link>
                            <Link to="/register" className="bg-indigo-600 text-white text-lg font-bold py-3 text-center rounded-lg shadow-md">Get Started</Link>
                        </div>
                    </div>
                )}
            </nav>

            {/* Hero Section */}
            <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 bg-white">
                <div className="container mx-auto px-6 text-center lg:text-left">
                    <div className="flex flex-col lg:flex-row items-center gap-12">
                        <div className="lg:w-1/2 space-y-8">
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-100 text-indigo-600 text-xs font-bold uppercase tracking-wider">
                                <CheckCircle2 size={14} /> Trusted by local businesses
                            </div>
                            <h1 className="text-5xl lg:text-6xl font-black text-slate-900 tracking-tight leading-tight">
                                Simplified GST Billing for <br />
                                <span className="text-indigo-600">Modern Businesses.</span>
                            </h1>
                            <p className="text-xl text-slate-500 font-medium leading-relaxed max-w-2xl">
                                Sri Lakshmi Enterprises provides a powerful yet simple billing platform
                                to manage your invoices, customers, and taxes effortlessly.
                            </p>
                            <div className="flex flex-col sm:flex-row items-center gap-4">
                                <Link to="/register" className="w-full sm:w-auto px-8 py-4 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-600/20 transition-all flex items-center justify-center gap-2">
                                    Create Your Account <ArrowRight size={18} />
                                </Link>
                                <button className="w-full sm:w-auto px-8 py-4 bg-white text-slate-700 font-bold rounded-xl border border-slate-200 hover:bg-slate-50 transition-all flex items-center justify-center gap-2">
                                    View Features
                                </button>
                            </div>
                            <div className="flex items-center justify-center lg:justify-start gap-8 pt-4">
                                <p className="text-sm font-semibold text-slate-400">Trusted by over 100+ entrepreneurs in your region.</p>
                            </div>
                        </div>
                        <div className="lg:w-1/2">
                            <div className="relative p-2 bg-slate-200 rounded-[2rem] shadow-2xl border border-slate-100">
                                <img
                                    src="/dashboard_mockup.png"
                                    alt="Application Dashboard"
                                    className="rounded-3xl w-full h-auto shadow-inner"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Features Grid */}
            <section id="features" className="py-24 bg-slate-50">
                <div className="container mx-auto px-6">
                    <div className="text-center max-w-2xl mx-auto mb-16">
                        <h2 className="text-base font-bold text-indigo-600 uppercase tracking-widest mb-4">Core Benefits</h2>
                        <h3 className="text-3xl lg:text-4xl font-black text-slate-900 tracking-tight">Everything you need to manage your billing.</h3>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                        {features.map((f, i) => (
                            <div key={i} className="p-8 bg-white rounded-3xl border border-slate-200 hover:border-indigo-300 hover:shadow-xl hover:shadow-indigo-500/5 transition-all group">
                                <div className="w-12 h-12 rounded-xl bg-slate-50 flex items-center justify-center mb-6 group-hover:bg-indigo-600 group-hover:text-white transition-all">
                                    {f.icon}
                                </div>
                                <h4 className="text-xl font-bold text-slate-900 mb-3">{f.title}</h4>
                                <p className="text-slate-500 font-medium text-sm leading-relaxed">{f.description}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* About / Proof Section */}
            <section id="about" className="py-24 bg-white">
                <div className="container mx-auto px-6">
                    <div className="flex flex-col lg:flex-row items-center gap-20">
                        <div className="lg:w-1/2 order-2 lg:order-1">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="p-8 bg-indigo-50 rounded-3xl space-y-4">
                                    <h4 className="text-4xl font-black text-indigo-600">100%</h4>
                                    <p className="text-sm font-bold text-indigo-900/60 uppercase tracking-widest">Compliance</p>
                                </div>
                                <div className="p-8 bg-slate-50 rounded-3xl space-y-4 translate-y-8">
                                    <h4 className="text-4xl font-black text-slate-900 italic">Fast</h4>
                                    <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Performance</p>
                                </div>
                                <div className="p-8 bg-slate-50 rounded-3xl space-y-4">
                                    <h4 className="text-4xl font-black text-slate-900">Secure</h4>
                                    <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Cloud Ready</p>
                                </div>
                                <div className="p-8 bg-emerald-50 rounded-3xl space-y-4 translate-y-8">
                                    <h4 className="text-4xl font-black text-emerald-600">2x</h4>
                                    <p className="text-sm font-bold text-emerald-900/60 uppercase tracking-widest">Efficiency</p>
                                </div>
                            </div>
                        </div>
                        <div className="lg:w-1/2 space-y-6 order-1 lg:order-2">
                            <h2 className="text-3xl lg:text-4xl font-black text-slate-900 tracking-tight leading-tight">
                                Designed for Sri Lakshmi Enterprises and the local market.
                            </h2>
                            <p className="text-lg text-slate-500 font-medium leading-relaxed">
                                We understand that every business is different. That's why we've built a billing system
                                that works for you—not the other way around. No complex software, no hidden fees,
                                just pure productivity.
                            </p>
                            <ul className="space-y-4">
                                {[
                                    "Automated GSTR-1 & 3B data preparation",
                                    "Direct PDF invoice sharing via Email/WhatsApp",
                                    "Real-time revenue tracking and goal setting",
                                    "Complete customer and vendor management"
                                ].map((item, i) => (
                                    <li key={i} className="flex items-center gap-3 text-slate-700 font-semibold">
                                        <CheckCircle2 size={18} className="text-indigo-600" /> {item}
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="py-24 bg-slate-50">
                <div className="container mx-auto px-6 text-center">
                    <div className="max-w-4xl mx-auto bg-white rounded-[3rem] p-12 lg:p-20 shadow-xl border border-slate-100">
                        <h2 className="text-4xl lg:text-5xl font-black text-slate-900 tracking-tight leading-tight mb-8">
                            Ready to automate your billing?
                        </h2>
                        <p className="text-xl text-slate-500 font-medium mb-12 max-w-2xl mx-auto">
                            Join local businesses and simplify your GST today. Start your free trial account in seconds.
                        </p>
                        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                            <Link to="/register" className="w-full sm:w-auto px-10 py-5 bg-indigo-600 text-white font-black rounded-xl hover:bg-indigo-700 shadow-lg transition-all active:scale-95">
                                Setup My Account
                            </Link>
                            <Link to="/login" className="w-full sm:w-auto px-10 py-5 bg-slate-100 text-slate-700 font-black rounded-xl hover:bg-slate-200 transition-all">
                                Sign In Instead
                            </Link>
                        </div>
                        <p className="mt-8 text-sm font-bold text-slate-400">Managed by Sri Lakshmi Enterprises &copy; 2026</p>
                    </div>
                </div>
            </section>

            {/* Basic Footer */}
            <footer className="py-12 bg-white border-t border-slate-100">
                <div className="container mx-auto px-6">
                    <div className="flex flex-col md:flex-row items-center justify-between gap-6">
                        <div className="flex items-center gap-2">
                            <div className="bg-slate-900 p-1.5 rounded-lg text-white">
                                <Sparkles size={16} />
                            </div>
                            <span className="text-lg font-bold tracking-tight font-space text-slate-900 uppercase">
                                GST<span className="text-indigo-600">.</span>EDGE
                            </span>
                        </div>
                        <div className="flex items-center gap-8">
                            <a href="#" className="text-sm font-semibold text-slate-400 hover:text-indigo-600 transition-colors">Privacy Policy</a>
                            <a href="#" className="text-sm font-semibold text-slate-400 hover:text-indigo-600 transition-colors">Terms of Service</a>
                            <a href="#" className="text-sm font-semibold text-slate-400 hover:text-indigo-600 transition-colors">Contact Support</a>
                        </div>
                        <p className="text-sm font-bold text-slate-400">© 2026 Sri Lakshmi Enterprises. All rights reserved.</p>
                    </div>
                </div>
            </footer>
        </div>
    );
};

export default Landing;
