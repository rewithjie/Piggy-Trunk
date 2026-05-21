import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Theme-aware color getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _surfaceDark => _isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
  Color get _borderDark => _isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
  Color get _textDark => _isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
  
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(

        children: [
          AdminSidebar(
            currentRoute: '/dashboard',
            onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          Expanded(
            child: Column(
              children: [
                /// REUSABLE TOP BAR
                ScreenTopBar(
                  adminName: 'Admin',
                  adminRole: 'SYSTEM ADMINISTRATOR',
                ),
                /// MAIN DASHBOARD CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: _surfaceDark.withOpacity(0.5),
                          border: Border.all(
                            color: _borderDark,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Dashboard Title
                            Text(
                              'Dashboard',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.04,
                              ),
                            ),
                            const SizedBox(height: 24),

                            /// KPI CARDS ROW (4 Cards)
                            _buildKpiCardsRow(),
                            const SizedBox(height: 32),

                            /// INVESTMENT ALLOCATION SECTION
                            _buildInvestmentAllocationSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// KPI CARDS ROW - 4 Cards Horizontal Scroll (Minimalist Design)
  Widget _buildKpiCardsRow() {
    final kpiData = [
      {'label': 'START OF INVESTMENT', 'value': '₱0'},
      {'label': 'NUMBER OF HOG BATCH', 'value': '0'},
      {'label': 'TOTAL CURRENT INVESTMENT', 'value': '₱0'},
      {'label': 'NUMBER OF MORTALITY', 'value': '0'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          kpiData.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              right: index < kpiData.length - 1 ? 16 : 0,
            ),
            child: _buildKpiCard(
              label: kpiData[index]['label'] as String,
              value: kpiData[index]['value'] as String,
            ),
          ),
        ),
      ),
    );
  }

  /// Individual KPI Card (Simple Box Design - No Icons)
  Widget _buildKpiCard({
    required String label,
    required String value,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceDark,
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mutedDark,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// INVESTMENT ALLOCATION SECTION
  Widget _buildInvestmentAllocationSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final cardWidth = isDesktop ? (constraints.maxWidth - 104) / 2 : 420.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _surfaceDark.withOpacity(0.2),
            border: Border.all(
              color: _borderDark,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVESTMENT ALLOCATION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildAllocationCard(
                      title: 'FATTENING',
                      percentage: '0%',
                      amount: '₱0',
                      width: cardWidth,
                    ),
                    _buildAllocationCard(
                      title: 'SOW',
                      percentage: '0%',
                      amount: '₱0',
                      width: cardWidth,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  /// Individual Allocation Card with Top Border Accent
  Widget _buildAllocationCard({
    required String title,
    required String percentage,
    required String amount,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _surfaceDark,
        border: Border.all(
          color: _borderDark,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card Content
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _mutedDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  percentage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



