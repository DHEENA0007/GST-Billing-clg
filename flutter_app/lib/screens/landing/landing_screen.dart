import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Dark elegant background
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _isScrolled ? const Color(0xFFF8FAFC).withOpacity(0.8) : Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 80.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.receipt_long, color: const Color(0xFF0F172A), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'GST Billing',
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (!isMobile)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavButton(title: 'Features'),
                            _NavButton(title: 'Pricing'),
                            _NavButton(title: 'Testimonials'),
                            const SizedBox(width: 32),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile)
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF475569),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              child: const Text('Sign In'),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => context.go('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: const Text('Get Started', style: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _HeroSection(isMobile: isMobile),
            _FeaturesSection(isMobile: isMobile),
            _StatsSection(isMobile: isMobile),
            _CTASection(isMobile: isMobile),
            _FooterSection(isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String title;
  const _NavButton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF475569),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  const _HeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 180,
        bottom: 80,
        left: isMobile ? 24 : 80,
        right: isMobile ? 24 : 80,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Color(0xFFFACC15), size: 16),
                      SizedBox(width: 8),
                      Text('The #1 GST Billing Software for Modern Teams', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Simplify Your Billing,\nAmplify Your Growth',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 40 : 72,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Automate GST compliance, track invoices in real-time, and manage your inventory with our AI-powered platform. Built for businesses that move fast.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: const Text('Start Free Trial', style: TextStyle(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        side: const BorderSide(color: Color(0xFF475569), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Book a Demo', style: TextStyle(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _DashboardMockup(isMobile: isMobile),
          ),
        ],
      ),
    );
  }
}

class _DashboardMockup extends StatelessWidget {
  final bool isMobile;
  const _DashboardMockup({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF475569), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 120,
            spreadRadius: -20,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Window Header
            Container(
              height: 48,
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                   Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _windowControl(const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _windowControl(const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _windowControl(const Color(0xFF10B981)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text('gstbilling.app/dashboard', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Window Body
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              color: const Color(0xFFF8FAFC).withOpacity(0.5),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _MockCard(height: isMobile ? 80 : 120, color: const Color(0xFF3B82F6).withOpacity(0.1), iconColor: const Color(0xFF3B82F6))),
                      SizedBox(width: isMobile ? 12 : 24),
                      Expanded(child: _MockCard(height: isMobile ? 80 : 120, color: const Color(0xFF10B981).withOpacity(0.1), iconColor: const Color(0xFF10B981))),
                      if (!isMobile) ...[
                        const SizedBox(width: 24),
                        Expanded(child: _MockCard(height: 120, color: const Color(0xFF8B5CF6).withOpacity(0.1), iconColor: const Color(0xFF8B5CF6))),
                        const SizedBox(width: 24),
                        Expanded(child: _MockCard(height: 120, color: const Color(0xFFF59E0B).withOpacity(0.1), iconColor: const Color(0xFFF59E0B))),
                      ],
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _MockCard(height: isMobile ? 150 : 300, color: Colors.white),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _MockCard(height: 300, color: Colors.white),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _windowControl(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MockCard extends StatelessWidget {
  final double height;
  final Color color;
  final Color? iconColor;

  const _MockCard({required this.height, required this.color, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF475569).withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: iconColor != null
          ? ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: iconColor!.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.show_chart, color: iconColor, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 8, width: 60, color: const Color(0xFF64748B).withOpacity(0.4)),
                    const SizedBox(height: 6),
                    Container(height: 14, width: 100, color: const Color(0xFF0F172A)),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 150, color: const Color(0xFF64748B).withOpacity(0.4)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;
  const _FeaturesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 120),
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EVERYTHING BUILT-IN',
              style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Powerful Features for Scale',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 32 : 48, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'We provide all the tools you need to run your business efficiently.',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF64748B), fontSize: isMobile ? 16 : 18),
          ),
          const SizedBox(height: 80),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossCount = width > 1000 ? 3 : (width > 650 ? 2 : 1);
              final itemWidth = (width - ((crossCount - 1) * 24)) / crossCount;
              final aspect = itemWidth / 240.0; // Ensuring good dynamic height 

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: aspect,
                children: const [
                  _PremiumFeatureCard(
                    icon: Icons.flash_on,
                    title: 'Lightning Fast Engine',
                    desc: 'Generate thousands of invoices per second smoothly and intuitively with our performant engine.',
                    gradient: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                  ),
                  _PremiumFeatureCard(
                    icon: Icons.account_balance,
                    title: '100% GST Compliant',
                    desc: 'Auto-calculate CGST, SGST, IGST with zero manual errors. Stay compliant with exact taxation rules.',
                    gradient: [Color(0xFF67E8F9), Color(0xFF06B6D4)],
                  ),
                  _PremiumFeatureCard(
                    icon: Icons.insights,
                    title: 'AI Business Insights',
                    desc: 'Utilize predictive machine-learning analytics to track your future cash flow scenarios.',
                    gradient: [Color(0xFFD8B4FE), Color(0xFFA855F7)],
                  ),
                  _PremiumFeatureCard(
                    icon: Icons.security,
                    title: 'Bank-grade Security',
                    desc: 'Industry standard Role-based access control and JWT-secured encrypted SQL data storage.',
                    gradient: [Color(0xFF86EFAC), Color(0xFF22C55E)],
                  ),
                  _PremiumFeatureCard(
                    icon: Icons.inventory,
                    title: 'Smart Inventory',
                    desc: 'Get immediate low stock alerts via email and track your specific product lifecycles automatically.',
                    gradient: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                  ),
                  _PremiumFeatureCard(
                    icon: Icons.receipt_long,
                    title: '1-Click Full Reports',
                    desc: 'GSTR-1, GSTR-3B, Profit Loss, Sales records natively exported to PDF or Excel instantly.',
                    gradient: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final List<Color> gradient;

  const _PremiumFeatureCard({required this.icon, required this.title, required this.desc, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF475569)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // prevent overflow
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: gradient[1].withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 28),
          ),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Expanded(
            child: Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final bool isMobile;
  const _StatsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 100),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 32 : 80),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), Color(0xFF7E22CE)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E22CE).withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 20),
            )
          ]
        ),
        child: Wrap(
          spacing: 64,
          runSpacing: 48,
          alignment: WrapAlignment.spaceEvenly,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            _StatItem(value: '10K+', label: 'Active Users'),
            _StatItem(value: '₹500Cr+', label: 'Invoices Generated'),
            _StatItem(value: '99.9%', label: 'Uptime SLA'),
            _StatItem(value: '24/7', label: 'Premium Support'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CTASection extends StatelessWidget {
  final bool isMobile;
  const _CTASection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 120),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.2), blurRadius: 40),
              ]
            ),
            child: const Icon(Icons.rocket_launch, size: 48, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 40),
          Text(
            'Ready to take control of your growth?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 36 : 56, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -1, height: 1.1),
          ),
          const SizedBox(height: 24),
          const Text(
            'Join thousands of businesses that trust GST Billing for their daily operational heavy-lifting.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              elevation: 8,
              shadowColor: const Color(0xFF0F172A).withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Get Started Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  final bool isMobile;
  const _FooterSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Colors.white)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 24,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('GST Billing App', style: TextStyle(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Text('© 2026 GST Billing. All rights reserved.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.facebook, color: Color(0xFF64748B))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.reddit, color: Color(0xFF64748B))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.link, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}
