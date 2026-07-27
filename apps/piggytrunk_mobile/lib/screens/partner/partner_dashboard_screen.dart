import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  bool _isLoading = false;
  String _partnerName = "Partner Investor";
  final double _totalInvested = 250000.00;
  final double _expectedReturn = 287500.00;
  final double _paidOut = 120000.00;

  @override
  void initState() {
    super.initState();
    _fetchPartnerData();
  }

  Future<void> _fetchPartnerData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Map<String, dynamic>? profile = await Supabase.instance.client
            .from('app_users')
            .select('user_id, name, email')
            .eq('supabase_user_id', user.id)
            .maybeSingle();

        if (profile == null && user.email != null && user.email!.isNotEmpty) {
          final profileByEmail = await Supabase.instance.client
              .from('app_users')
              .select('user_id, name, email')
              .eq('email', user.email!)
              .maybeSingle();

          if (profileByEmail != null) {
            profile = profileByEmail;
            try {
              await Supabase.instance.client
                  .from('app_users')
                  .update({'supabase_user_id': user.id})
                  .eq('user_id', profileByEmail['user_id']);
            } catch (e) {
              debugPrint('Error linking supabase_user_id: $e');
            }
          }
        }

        String resolvedName = "";
        if (profile != null) {
          final rawName = profile['name'] as String?;
          if (rawName != null && rawName.trim().isNotEmpty) {
            resolvedName = rawName.trim();
          }
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
            _partnerName = resolvedName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching partner profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: AppBar(
        title: Text(
          'Investor Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF18314F),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF18314F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Text(
                    'Magandang Araw, $_partnerName! 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Narito ang overview ng iyong mga pamumuhunan.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Investment Summary Cards
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18314F).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Kabuuang Puhunan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: PiggyTrunkTheme.ptMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₱${_totalInvested.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF18314F),
                            ),
                          ),
                          const Divider(height: 32, color: PiggyTrunkTheme.ptBorder),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Inaasahang Balik',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: PiggyTrunkTheme.ptMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${_expectedReturn.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Na-Pay out Na',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: PiggyTrunkTheme.ptMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${_paidOut.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF18314F),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Investments Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mga Aktibong Puhunan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18314F),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Tingnan Lahat', style: TextStyle(color: Color(0xFF18314F))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Investment List Items
                  _buildInvestmentItem('Batch 12: Hog Grower Project', '₱100,000.00', 'Expected Return: ₱115,000.00', 'In Progress', Colors.amber[800]!),
                  const SizedBox(height: 12),
                  _buildInvestmentItem('Batch 10: Weanling Feeds Fund', '₱150,000.00', 'Expected Return: ₱172,500.00', 'Paid Out', Colors.green[700]!),
                ],
              ),
            ),
    );
  }

  Widget _buildInvestmentItem(String title, String amount, String detail, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF18314F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PiggyTrunkTheme.ptMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF18314F),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
