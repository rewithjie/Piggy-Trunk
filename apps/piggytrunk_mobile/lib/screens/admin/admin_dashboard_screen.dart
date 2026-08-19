import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_inventory_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_investment_screen.dart';
import 'admin_distribution_portal_screen.dart';
import '../../services/auth_session_service.dart';

class AdminMobileDashboardScreen extends StatefulWidget {
  const AdminMobileDashboardScreen({super.key});

  @override
  State<AdminMobileDashboardScreen> createState() =>
      _AdminMobileDashboardScreenState();
}

class _AdminMobileDashboardScreenState
    extends State<AdminMobileDashboardScreen> {
  // Brand color tokens
  static const Color _brandNavy = Color(0xFF18314F);
  static const Color _primarySlate = Color(0xFF243B53);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF6F8096);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _emeraldGreen = Color(0xFF10B981);

  int _selectedTabIndex = 0;
  bool _isLoading = false;
  String _adminName = "Admin";
  double _totalInvested = 0.00;
  double _totalInventoryValue = 0.00;
  List<Map<String, dynamic>> _stockAlerts = [];
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Fetch Admin profile name
        final profile = await Supabase.instance.client
            .from('app_users')
            .select('name, email')
            .eq('supabase_user_id', user.id)
            .maybeSingle();

        String resolvedName = "";
        if (profile != null && profile['name'] != null) {
          final n = (profile['name'] as String).trim();
          if (n.isNotEmpty) resolvedName = n;
        }

        if (resolvedName.isEmpty) {
          final metaName = (user.userMetadata?['name'] as String?) ??
              (user.userMetadata?['full_name'] as String?);
          if (metaName != null && metaName.trim().isNotEmpty) {
            resolvedName = metaName.trim();
          } else if (user.email != null && user.email!.contains('@')) {
            final prefix = user.email!.split('@').first.trim();
            if (prefix.isNotEmpty) {
              resolvedName = prefix[0].toUpperCase() + prefix.substring(1);
            }
          }
        }

        if (resolvedName.isNotEmpty && mounted) {
          setState(() {
            _adminName = resolvedName;
          });
        }
      }

      // Fetch live investments sum
      try {
        final investRes = await Supabase.instance.client
            .from('investments')
            .select('amount');

        if (investRes.isNotEmpty && mounted) {
          double sumInvest = 0;
          for (var i in investRes) {
            sumInvest += (i['amount'] as num?)?.toDouble() ?? 0.0;
          }
          setState(() => _totalInvested = sumInvest);
        } else if (mounted) {
          setState(() => _totalInvested = 0.0);
        }
      } catch (_) {}

      // Fetch live products inventory value
      try {
        final products = await Supabase.instance.client
            .from('inventory_products')
            .select('price, units')
            .eq('is_archived', false);

        if (products.isNotEmpty && mounted) {
          double totalVal = 0;
          for (var p in products) {
            final price = (p['price'] as num?)?.toDouble() ?? 0.0;
            final units = (p['units'] as num?)?.toInt() ?? 0;
            totalVal += (price * units);
          }
          setState(() => _totalInventoryValue = totalVal);
        } else if (mounted) {
          setState(() => _totalInventoryValue = 0.0);
        }
      } catch (_) {}

      // Fetch live critical stock alerts
      try {
        final alertRes = await Supabase.instance.client
            .from('inventory_products')
            .select('id, name, category, units, price')
            .eq('is_archived', false)
            .lte('units', 15)
            .order('units', ascending: true);

        if (alertRes.isNotEmpty && mounted) {
          List<Map<String, dynamic>> parsedAlerts = [];
          for (var p in alertRes) {
            final int units = (p['units'] as num?)?.toInt() ?? 0;
            final bool isCritical = units <= 5;
            final double ratio =
                units > 0 ? (units / 100).clamp(0.05, 1.0) : 0.0;
            parsedAlerts.add({
              'name': (p['name'] as String?)?.toUpperCase() ?? 'FEED PRODUCT',
              'category': (p['category'] as String?) ?? 'Feed Sack',
              'type': isCritical ? 'CRITICAL STOCK' : 'LOW STOCK',
              'time': 'Recent',
              'percentage': ratio,
              'percentText': '${(ratio * 100).toInt()}% ($units left)',
              'isCritical': isCritical,
              'icon': Icons.inventory_2_rounded,
              'color': isCritical ? _criticalRed : _warningAmber,
            });
          }
          setState(() => _stockAlerts = parsedAlerts);
        } else if (mounted) {
          setState(() => _stockAlerts = []);
        }
      } catch (_) {
        if (mounted) setState(() => _stockAlerts = []);
      }
    } catch (e) {
      debugPrint('Admin fetch data error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: _brandNavy,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of the Admin Console?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _criticalRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthSessionService().clearSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '₱ ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '₱ $intPart.${parts[1]}';
    }
    return '₱ ${amount.toStringAsFixed(2)}';
  }

  void _showQuickActionModal(String actionTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _brandNavy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Quick action form for $actionTitle. Fill out the details below to submit.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes / Reference',
                hintText: 'Enter details for $actionTitle...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primarySlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$actionTitle recorded successfully.'),
                      backgroundColor: _emeraldGreen,
                    ),
                  );
                },
                child: Text(
                  'Confirm $actionTitle',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_selectedTabIndex != 0) {
          setState(() => _selectedTabIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pindutin ulit ang Back button upang isara ang app.'),
              duration: Duration(seconds: 2),
              backgroundColor: _brandNavy,
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
        child: RefreshIndicator(
          color: _brandNavy,
          onRefresh: _fetchAdminData,
          child: _selectedTabIndex == 0
              ? _buildDashboardView()
              : _selectedTabIndex == 1
                  ? AdminMobileInventoryScreen(
                      onBackToDashboard: () =>
                          setState(() => _selectedTabIndex = 0),
                    )
                  : _selectedTabIndex == 2
                      ? AdminMobileInvestmentScreen(
                          onBackToDashboard: () =>
                              setState(() => _selectedTabIndex = 0),
                        )
                      : _selectedTabIndex == 3
                          ? AdminMobileDistributionPortalScreen(
                              onBackToDashboard: () =>
                                  setState(() => _selectedTabIndex = 0),
                            )
                          : _buildPlaceholderTab(_selectedTabIndex),
        ),
      ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            const LinearProgressIndicator(
              minHeight: 2.5,
              color: _brandNavy,
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 8),
          ],
          // Top Header: Greeting & Admin Full Name
          _buildHeader(),
          const SizedBox(height: 22),

          // Stacked Metric Cards (Total Invested & Total Inventory Value)
          _buildMetricCards(),
          const SizedBox(height: 28),

          // Quick Actions Section
          _buildQuickActionsSection(),
          const SizedBox(height: 28),

          // Recent Stock Alerts Section
          _buildRecentStockAlertsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. Header: Greeting & Admin Name
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello Admin,',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textMuted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _adminName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Top right Action buttons (Notification / Logout)
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: _brandNavy, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new administrative notifications.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFF64748B), size: 20),
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Metric Summary Cards (Vertical Stack with Brand Gradients)
  Widget _buildMetricCards() {
    return Column(
      children: [
        // Card 1: Total Invested (Deep Brand Navy Gradient)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF18314F),
                Color(0xFF243B53),
                Color(0xFF1E3A5F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18314F).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Invested',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatCurrency(_totalInvested),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 2: Total Inventory Value (Slate-Emerald Gradient)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B4C7E),
                Color(0xFF335C96),
                Color(0xFF24487A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B4C7E).withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Inventory Value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatCurrency(_totalInventoryValue),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Displaying all quick actions.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'View all',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC73F57),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Action Buttons Row (Restock, New Investment, Request)
        Row(
          children: [
            // Restock Action Card
            Expanded(
              child: _buildActionCard(
                label: 'Restock',
                icon: Icons.add_rounded,
                badgeBg: const Color(0xFFFFECEE),
                badgeIconColor: const Color(0xFFE11D48),
                onTap: () => _showQuickActionModal('Restock Inventory'),
              ),
            ),
            const SizedBox(width: 12),

            // New Investment Action Card
            Expanded(
              child: _buildActionCard(
                label: 'New Investment',
                icon: Icons.bar_chart_rounded,
                badgeBg: const Color(0xFFECFDF5),
                badgeIconColor: _emeraldGreen,
                onTap: () => _showQuickActionModal('New Investment'),
              ),
            ),
            const SizedBox(width: 12),

            // Request Action Card
            Expanded(
              child: _buildActionCard(
                label: 'Request',
                icon: Icons.assignment_outlined,
                badgeBg: const Color(0xFFEFF6FF),
                badgeIconColor: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminMobileRequestsScreen(
                        onBackToDashboard: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String label,
    required IconData icon,
    required Color badgeBg,
    required Color badgeIconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeIconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _brandNavy,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Recent Stock Alerts Section with Progress Indicators
  Widget _buildRecentStockAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Stock Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedTabIndex = 1); // Switch to Inventory
              },
              child: Text(
                'See all',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC73F57),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Alert Cards or Empty State
        if (_stockAlerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _emeraldGreen,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Critical Stock Alerts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _brandNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All feed inventory items are in healthy levels or no products have been added yet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockAlerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = _stockAlerts[index];
            final bool isCritical = alert['isCritical'] as bool;
            final double percentage = (alert['percentage'] as num).toDouble();
            final Color alertColor =
                isCritical ? _criticalRed : _warningAmber;

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Accent Left Bar
                    Container(
                      width: 5,
                      color: alertColor,
                    ),

                    // Card Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thumbnail container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Icon(
                                alert['icon'] as IconData,
                                color: const Color(0xFF64748B),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Product details & progress
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge and timestamp
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        alert['type'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: alertColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        alert['time'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Product Name
                                  Text(
                                    alert['name'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _brandNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // Progress Bar + Percentage Text
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: percentage,
                                            minHeight: 6,
                                            backgroundColor:
                                                const Color(0xFFE2E8F0),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    alertColor),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        alert['percentText'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. Placeholder Views for sub-tabs (Inventory, Investment, POS)
  Widget _buildPlaceholderTab(int index) {
    final titles = ['Dashboard', 'Inventory', 'Investment', 'POS'];
    final icons = [
      Icons.dashboard_rounded,
      Icons.inventory_2_outlined,
      Icons.assignment_outlined,
      Icons.point_of_sale_rounded,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _brandNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icons[index], color: _brandNavy, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              '${titles[index]} Console',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _brandNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage real-time ${titles[index].toLowerCase()} records directly from this mobile console.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primarySlate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => setState(() => _selectedTabIndex = 0),
              child: Text(
                'Back to Dashboard',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Bottom Navigation Bar (4 Dedicated Tabs: Dashboard, Inventory, Investment, POS)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFC73F57), // Active accent
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded, size: 24),
            activeIcon: Icon(Icons.dashboard_rounded, size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined, size: 24),
            activeIcon: Icon(Icons.inventory_2_rounded, size: 24),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 24),
            activeIcon: Icon(Icons.assignment_rounded, size: 24),
            label: 'Investment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined, size: 24),
            activeIcon: Icon(Icons.point_of_sale_rounded, size: 24),
            label: 'POS',
          ),
        ],
      ),
    );
  }
}
