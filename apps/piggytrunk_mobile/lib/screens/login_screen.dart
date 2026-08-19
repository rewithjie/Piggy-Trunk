import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/services/notification_service.dart';
import '../services/google_auth_service.dart';
import '../services/auth_session_service.dart';
import '../utils/screen_fit_util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _identifierError;
  String? _passwordError;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_identifierError != null || _passwordError != null || _errorMessage != null) {
      setState(() {
        _identifierError = null;
        _passwordError = null;
        _errorMessage = null;
      });
    }
  }

  Widget _buildInlineError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.5),
            child: Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordSignIn(String targetRole) async {
    _clearErrors();

    final String identifier = _usernameController.text.trim();
    final String password = _passwordController.text;

    String? idErr;
    String? passErr;

    final cleanId = identifier.trim().toLowerCase();
    if (cleanId.isEmpty) {
      idErr = 'Mangyaring ilagay ang iyong Username o Gmail.';
    } else if (cleanId.contains('gmail') && !cleanId.contains('@')) {
      idErr = 'Kulang ng "@" ang Gmail address (hal. name@gmail.com).';
    }

    if (password.isEmpty) {
      passErr = 'Mangyaring ilagay ang iyong password.';
    } else if (password.length < 6) {
      passErr = 'Ang password ay dapat hindi bababa sa 6 na karakter.';
    }

    if (idErr != null || passErr != null) {
      setState(() {
        _identifierError = idErr;
        _passwordError = passErr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String emailToUse = identifier;
      if (!identifier.contains('@')) {
        try {
          final res = await Supabase.instance.client
              .from('app_users')
              .select('email')
              .ilike('name', identifier)
              .maybeSingle();

          if (res != null && res['email'] != null) {
            emailToUse = res['email'];
          }
        } catch (_) {
          // Gracefully fallback if username lookup fails
        }
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Maling account o password.');
      }

      final userData = await Supabase.instance.client
          .from('app_users')
          .select('role, status')
          .or('supabase_user_id.eq.${user.id},email.eq.${user.email}')
          .maybeSingle();

      final String rawStatus = (userData?['status'] ?? 'Pending').toString();
      final String statusLower = rawStatus.toLowerCase();
      final String role = userData?['role']?.toString() ?? targetRole;

      if (statusLower == 'pending' || statusLower == 'inactive') {
        await Supabase.instance.client.auth.signOut();
        await AuthSessionService().clearSession();
        if (mounted) _showPendingDialog();
      } else {
        await AuthSessionService().saveSession(
          email: user.email ?? emailToUse,
          role: role,
          loginMethod: 'password',
          userId: user.id,
        );
        if (mounted) _navigateToDashboard(role);
      }
    } on AuthException catch (_) {
      // Smart check: Does this user exist in app_users?
      bool userExists = false;
      try {
        final existing = await Supabase.instance.client
            .from('app_users')
            .select('user_id')
            .or('email.ilike.$identifier,name.ilike.$identifier')
            .maybeSingle();
        userExists = existing != null;
      } catch (_) {}

      if (!userExists) {
        setState(() {
          _identifierError = 'Walang natagpuang account. Mangyaring gumawa muna ng account bago mag-login.';
        });
      } else {
        setState(() {
          _passwordError = 'Maling password. Pakisuri ang iyong password at subukang muli.';
        });
      }
    } catch (e) {
      setState(() {
        _passwordError = 'Maling Email o Password. Mangyaring subukang muli.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn(String targetRole) async {
    setState(() {
      _errorMessage = null;
      _identifierError = null;
      _passwordError = null;
      _isGoogleLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle(
        targetRole: targetRole,
        isSignUpMode: false,
      );

      if (result['success'] == true) {
        final String rawStatus = (result['status'] ?? 'pending').toString();
        final String statusLower = rawStatus.toLowerCase();
        final String role = (result['role'] ?? targetRole).toString();
        final String? googleEmail = result['email'];

        final bool isActuallyActive = statusLower == 'active' || statusLower == 'approved';

        if (!isActuallyActive) {
          // Double-check database directly in case of stale status
          bool dbActive = false;
          if (googleEmail != null && googleEmail.isNotEmpty) {
            try {
              final freshUser = await Supabase.instance.client
                  .from('app_users')
                  .select('status, role')
                  .eq('email', googleEmail)
                  .maybeSingle();
              if (freshUser != null) {
                final st = (freshUser['status'] ?? '').toString().toLowerCase();
                if (st == 'active' || st == 'approved') {
                  dbActive = true;
                }
              }
            } catch (_) {}
          }

          if (dbActive) {
            if (googleEmail != null) {
              await AuthSessionService().saveSession(
                email: googleEmail,
                role: role,
                loginMethod: 'google',
              );
            }
            if (mounted) _navigateToDashboard(role);
            return;
          }

          await Supabase.instance.client.auth.signOut();
          await AuthSessionService().clearSession();
          if (mounted) _showPendingDialog();
        } else {
          if (googleEmail != null && googleEmail.isNotEmpty) {
            await AuthSessionService().saveSession(
              email: googleEmail,
              role: role,
              loginMethod: 'google',
            );
          }
          if (mounted) _navigateToDashboard(role);
        }
      } else if (result['message'] != null && result['message'] != 'Canceled Google sign-in.') {
        final rawMsg = result['message'].toString();
        if (rawMsg.contains('Walang nakalaang account') || rawMsg.contains('mag-Sign Up muna')) {
          setState(() {
            _identifierError = 'Walang natagpuang account para sa Google account na ito. Mangyaring mag-rehistro muna.';
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sa Google Login: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nagawa na ang Account!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF18314F),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Matagumpay na naitala ang iyong account!\n\nKasalukuyan pa itong naghihintay ng pag-apruba mula sa Admin bago ka makapasok sa Dashboard.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18314F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Naintindihan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDashboard(String role) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await NotificationService().requestPermission();
      NotificationService().startRoleRealtimeListener(role: role, userId: user.id);
    }

    if (!mounted) return;

    switch (role) {
      case 'hog_raiser':
      case 'raiser':
        Navigator.of(context).pushNamedAndRemoveUntil('/raiser_dashboard', (route) => false);
        break;
      case 'partner':
      case 'investor':
        Navigator.of(context).pushNamedAndRemoveUntil('/partner_dashboard', (route) => false);
        break;
      case 'cashier':
        Navigator.of(context).pushNamedAndRemoveUntil('/cashier_dashboard', (route) => false);
        break;
      case 'admin':
        Navigator.of(context).pushNamedAndRemoveUntil('/admin_dashboard', (route) => false);
        break;
      default:
        Supabase.instance.client.auth.signOut();
        setState(() {
          _errorMessage =
              'Walang nahanap na angkop na dashboard para sa iyong role.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Universal ScreenFit Auto-Scaling
    final fit = ScreenFit(context);
    final double logoHeight = fit.dp(84.0);
    final double logoScale = 1.0;
    final double titleFontSize = fit.sp(22.0);
    final double subtitleFontSize = fit.sp(14.0);
    final double fieldSpacing = fit.dp(8.0);
    final double labelFontSize = fit.sp(14.0);
    final double inputPaddingV = fit.dp(10.0);
    final double inputFontSize = fit.sp(15.0);
    final double cardPaddingH = fit.dp(18.0);
    final double cardPaddingV = fit.dp(12.0);
    final double buttonHeight = fit.dp(48.0);
    final double textOffsetV = 0.0;

    final String role =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'hog_raiser';
    final String displayRole = role == 'hog_raiser'
        ? 'Hog Raiser'
        : role == 'partner'
        ? 'Partner Investor'
        : role == 'cashier'
        ? 'Cashier'
        : 'Admin';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F7FB), Color(0xFFE8EEF5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // FIXED TOP HEADER SECTION (Anchored at Top - Never Scrolls)
              Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  top: 6.0,
                  right: 20.0,
                  bottom: 2.0,
                ),
                child: Column(
                  children: [
                    // Bumalik Button Top Left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(
                              context,
                              '/onboarding',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Color(0xFF18314F),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Bumalik',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF18314F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: fieldSpacing * 0.4),

                    // Prominent Piggy Trunk Logo (Fixed Position with MediaQuery Height)
                    Transform.scale(
                      scale: logoScale,
                      child: Image.asset(
                        'assets/piggytrunk_logo.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: logoHeight * 0.9,
                          height: logoHeight * 0.9,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18314F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: logoHeight * 0.45,
                          ),
                        ),
                      ),
                    ),

                    // Titles shifted UP closer to logo graphic
                    Transform.translate(
                      offset: Offset(0, textOffsetV),
                      child: Column(
                        children: [
                          // Brand Name Text: "Piggy Trunk"
                          Text(
                            'Piggy Trunk',
                            style: TextStyle(
                              fontSize: titleFontSize + 2,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF18314F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Action Title "Mag-Sign In"
                          Text(
                            'Mag-Sign In',
                            style: TextStyle(
                              fontSize: titleFontSize - 1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF18314F),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle: Mag-login bilang Hog Raiser
                          Text(
                            'Mag-login bilang $displayRole',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6F8096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // SCROLLABLE FORM BODY (Below Fixed Header)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPaddingH,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE53935),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFE53935),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFC62828),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Main White Elevation Card Container
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: cardPaddingH,
                            vertical: cardPaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF18314F,
                                ).withValues(alpha: 0.07),
                                blurRadius: 24,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username/Email Label
                              Text(
                                'Username o Email Address',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Username Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _identifierError != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFFCBD5E1),
                                    width: _identifierError != null ? 1.5 : 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    fontSize: inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18314F),
                                  ),
                                  onChanged: (_) {
                                    if (_identifierError != null) {
                                      setState(() => _identifierError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: inputPaddingV,
                                    ),
                                    border: InputBorder.none,
                                    hintText: 'hal. juan@gmail.com',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF64748B),
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                              _buildInlineError(_identifierError),
                              SizedBox(height: fieldSpacing),

                              // Password Label
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Password Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _passwordError != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFFCBD5E1),
                                    width: _passwordError != null ? 1.5 : 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    fontSize: inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18314F),
                                  ),
                                  onChanged: (_) {
                                    if (_passwordError != null) {
                                      setState(() => _passwordError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: inputPaddingV,
                                    ),
                                    border: InputBorder.none,
                                    hintText: 'Ilagay ang iyong password',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF64748B),
                                      size: 19,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: const Color(0xFF64748B),
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildInlineError(_passwordError),
                              SizedBox(height: fieldSpacing * 0.6),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Kontakin ang Admin para sa pag-reset ng password.',
                                        ),
                                        backgroundColor: Color(0xFF18314F),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Nakalimutan ang Password?',
                                    style: TextStyle(
                                      fontSize: labelFontSize - 0.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2366CC),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: fieldSpacing * 1.2),

                              // Sign In Button (Piggy Brand Navy Gradient without arrow icon)
                              Container(
                                width: double.infinity,
                                height: buttonHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF18314F),
                                      Color(0xFF243B53),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF18314F,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handlePasswordSignIn(role),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.center,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Mag-Sign In Na',
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divider with "o kaya gamitin ang"
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      'o kaya gamitin ang',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Sign in with Google Button (Official Google Sign-In Pill Style)
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25.0),
                                  border: Border.all(
                                    color: const Color(0xFF747775),
                                    width: 1.0,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isGoogleLoading
                                      ? null
                                      : () => _handleGoogleSignIn(role),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1F1F1F),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                  ),
                                  child: _isGoogleLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF18314F),
                                                ),
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            OfficialGoogleLogo(size: 22),
                                            SizedBox(width: 12),
                                            Text(
                                              'Mag-Sign in gamit ang Google',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F1F1F),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Create an account Link (Aligned color + Underline)
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/signup',
                                      arguments: role,
                                    );
                                  },
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF64748B),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Wala ka pang account? ',
                                        ),
                                        TextSpan(
                                          text: 'Gumawa ng Account',
                                          style: TextStyle(
                                            color: Color(0xFF18314F),
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFF18314F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfficialGoogleLogo extends StatelessWidget {
  final double size;
  const OfficialGoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/512px-Google_%22G%22_logo.svg.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = size.width * 0.22;
    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius - (strokeWidth / 2),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red Arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -0.785398, -1.8326, false, paint);

    // Yellow Arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -2.61799, -1.309, false, paint);

    // Green Arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -3.92699, -1.309, false, paint);

    // Blue Arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -5.23599, -1.1, false, paint);

    // Blue Bar
    final Paint fillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Rect barRect = Rect.fromLTRB(
      center.dx,
      center.dy - (strokeWidth / 2),
      size.width,
      center.dy + (strokeWidth / 2),
    );
    canvas.drawRect(barRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
