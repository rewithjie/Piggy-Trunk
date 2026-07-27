import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class AdminMobileDashboardScreen extends StatefulWidget {
  const AdminMobileDashboardScreen({super.key});

  @override
  State<AdminMobileDashboardScreen> createState() => _AdminMobileDashboardScreenState();
}

class _AdminMobileDashboardScreenState extends State<AdminMobileDashboardScreen> {
  bool _isLoading = false;
  String _adminName = "System Admin";
  List<Map<String, dynamic>> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
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
            _adminName = resolvedName;
          });
        }
      }
      
      // Fetch pending users
      final users = await Supabase.instance.client
          .from('app_users')
          .select('user_id, name, role, email')
          .eq('status', 'Pending');
      if (mounted) {
        setState(() {
          _pendingUsers = List<Map<String, dynamic>>.from(users);
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
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

  Future<void> _approveUser(int userId, String name) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('app_users')
          .update({'status': 'active'})
          .eq('user_id', userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Matagumpay na in-approve ang account ni $name.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }
      _fetchAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.plusJakartaSans(
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Text(
                    'Magandang Araw, $_adminName! ⚙️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mobile console para sa pag-approve ng users.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title of Stock Release
                  Text(
                    'Nakabinbing Account Approvals (${_pendingUsers.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Approval List Items
                  Expanded(
                    child: _pendingUsers.isEmpty
                        ? Center(
                            child: Text(
                              'Walang nakabinbing user approvals.',
                              style: GoogleFonts.plusJakartaSans(
                                color: PiggyTrunkTheme.ptMuted,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _pendingUsers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = _pendingUsers[index];
                              final String role = user['role'] as String;
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
                                            user['name'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF18314F),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: PiggyTrunkTheme.ptMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: PiggyTrunkTheme.ptPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _approveUser(
                                        user['user_id'] as int,
                                        user['name'] as String,
                                      ),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: PiggyTrunkTheme.ptSuccess,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
