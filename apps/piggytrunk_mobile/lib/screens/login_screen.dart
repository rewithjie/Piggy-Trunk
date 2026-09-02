import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/services/notification_service.dart';
import '../services/google_auth_service.dart';
import '../services/auth_session_service.dart';
import '../utils/screen_fit_util.dart';
import '../widgets/piggy_toast.dart';
import '../widgets/role_selection_modal.dart';

const String googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

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
  String? _targetRole;
  String? _errorMessage;
  String? _identifierError;
  String? _passwordError;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _targetRole = args;
    } else if (args is Map && args['role'] != null) {
      _targetRole = args['role'].toString();
    }
  }

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

  Future<void> _handlePasswordSignIn() async {
    _clearErrors();

    final String identifier = _usernameController.text.trim();
    final String password = _passwordController.text;

    String? idErr;
    String? passErr;

    final cleanId = identifier.trim().toLowerCase();
    if (cleanId.isEmpty) {
      idErr = 'Please enter your Username or Gmail address.';
    } else if (cleanId.contains('gmail') && !cleanId.contains('@')) {
      idErr = 'Please include "@" in your email address (e.g. name@gmail.com).';
    }

    if (password.isEmpty) {
      passErr = 'Please enter your password.';
    } else if (password.length < 6) {
      passErr = 'Password must be at least 6 characters.';
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

    String emailToUse = identifier;

    try {
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
        throw Exception('Invalid account credentials.');
      }

      final userData = await Supabase.instance.client
          .from('app_users')
          .select('role, status')
          .or('supabase_user_id.eq.${user.id},email.eq.${user.email}')
          .maybeSingle();

      final String rawStatus = (userData?['status'] ?? 'Pending').toString();
      final String statusLower = rawStatus.toLowerCase();
      final String role = (userData?['role'] ?? 'hog_raiser').toString();

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
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        if (mounted) _showUnconfirmedEmailDialog(emailToUse);
      } else {
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
            _identifierError = 'No registered account found. Please create an account before signing in.';
          });
        } else {
          setState(() {
            _passwordError = 'Incorrect password. Please verify and try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _passwordError = 'Invalid Email or Password. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _identifierError = null;
      _passwordError = null;
      _isGoogleLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle(
        isSignUpMode: false,
      );

      if (result['success'] == true) {
        final bool isNewUser = result['is_new_user'] == true;
        final String? googleEmail = result['email'];
        final String googleName = result['name'] ?? 'User';

        if (isNewUser) {
          // Brand new user: trigger RoleSelectionModal on the spot
          if (mounted) {
            setState(() => _isGoogleLoading = false);
            final String? chosenRole = await RoleSelectionModal.show(
              context,
              userName: googleName,
            );

            if (chosenRole != null && googleEmail != null) {
              setState(() => _isGoogleLoading = true);
              final regResult = await _googleAuthService.completeGoogleRegistration(
                email: googleEmail,
                selectedRole: chosenRole,
                fullName: googleName,
              );

              if (regResult['success'] == true) {
                await Supabase.instance.client.auth.signOut();
                await AuthSessionService().clearSession();
                if (mounted) _showPendingDialog();
              } else {
                setState(() {
                  _errorMessage = regResult['message'] ?? 'Failed to complete registration.';
                });
              }
            }
          }
          return;
        }

        // Returning user: read detected role and status
        final String rawStatus = (result['status'] ?? 'pending').toString();
        final String statusLower = rawStatus.toLowerCase();
        final String role = (result['role'] ?? 'hog_raiser').toString();
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
      } else if (result['message'] != null && result['message'] != 'Canceled Google sign-in.' && result['message'] != 'Google Sign-In was canceled.') {
        final rawMsg = result['message'].toString();
        if (rawMsg.contains('Walang nakalaang account') || rawMsg.contains('mag-Sign Up muna') || rawMsg.contains('No registered account')) {
          setState(() {
            _identifierError = 'No registered account found for this Google account. Please sign up first.';
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In error: ${e.toString()}';
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
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Account Pending Approval',
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
          'Your account has been registered and is currently awaiting Admin approval before you can access the dashboard.\n\nWe will notify you once approved!',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.45,
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
                'Got It',
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

  void _showUnconfirmedEmailDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Color(0xFF2563EB), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email Not Confirmed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF18314F),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'A confirmation email was sent to $email.\n\nPlease check your inbox (and spam folder) and click the confirmation link before signing in.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.45,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    try {
                      await Supabase.instance.client.auth.resend(
                        type: OtpType.signup,
                        email: email,
                      );
                      if (mounted) {
                        PiggyToast.showSuccess(
                          context,
                          'Verification email resent to $email',
                          title: 'Email Sent',
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        PiggyToast.showError(
                          context,
                          'Failed to resend confirmation email: ${e.toString()}',
                          title: 'Error',
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Resend Link',
                    style: TextStyle(
                      color: Color(0xFF18314F),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18314F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
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
              'No appropriate dashboard found for your assigned role.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Universal ScreenFit Auto-Scaling
    final fit = ScreenFit(context);
    final double logoHeight = fit.dp(96.0);
    final double logoScale = 1.15;
    final double titleFontSize = fit.sp(22.0);
    final double subtitleFontSize = fit.sp(13.5);
    final double fieldSpacing = fit.dp(8.0);
    final double labelFontSize = fit.sp(14.0);
    final double inputPaddingV = fit.dp(10.0);
    final double inputFontSize = fit.sp(15.0);
    final double cardPaddingH = fit.dp(18.0);
    final double cardPaddingV = fit.dp(12.0);
    final double buttonHeight = fit.dp(54.0);
    final double textOffsetV = 0.0;

    const String backText = 'Back';
    const String actionTitle = 'Sign In';

    String roleLabel = '';
    IconData? roleIcon;
    if (_targetRole != null) {
      final r = _targetRole!.toLowerCase();
      if (r.contains('cashier')) {
        roleLabel = 'Cashier';
        roleIcon = Icons.point_of_sale_rounded;
      } else if (r.contains('partner') || r.contains('investor')) {
        roleLabel = 'Partner Investor';
        roleIcon = Icons.trending_up_rounded;
      } else if (r.contains('raiser')) {
        roleLabel = 'Hog Raiser';
        roleIcon = Icons.pets_rounded;
      }
    }

    final String subtitleText = roleLabel.isNotEmpty
        ? 'Sign in to continue as $roleLabel'
        : 'Welcome back! Sign in to continue';

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
                    // Back / Bumalik Button Top Left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(
                              context,
                              '/signup',
                              arguments: _targetRole,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Color(0xFF18314F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                backText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: titleFontSize + 2,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF18314F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Action Title "Sign In"
                          Text(
                            actionTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: titleFontSize - 1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF18314F),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle: Dynamic based on registered role
                          Text(
                            subtitleText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6F8096),
                            ),
                          ),
                          if (roleLabel.isNotEmpty && roleIcon != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18314F).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF18314F).withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                roleIcon,
                                size: 20,
                                color: const Color(0xFF18314F),
                              ),
                            ),
                          ],
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
                                'Username or Email Address',
                                style: GoogleFonts.plusJakartaSans(
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
                                        : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  cursorColor: const Color(0xFF18314F),
                                  keyboardType: TextInputType.emailAddress,
                                  textCapitalization: TextCapitalization.none,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => _clearErrors(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: inputFontSize,
                                    color: const Color(0xFF18314F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    hintText: 'Enter username or email',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF64748B),
                                      fontSize: inputFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF18314F),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: inputPaddingV,
                                      horizontal: 14,
                                    ),
                                  ),
                                ),
                              ),
                              _buildInlineError(_identifierError),
                              SizedBox(height: fieldSpacing * 0.8),

                              // Password Label
                              Text(
                                'Password',
                                style: GoogleFonts.plusJakartaSans(
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
                                        : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  cursorColor: const Color(0xFF18314F),
                                  obscureText: _obscurePassword,
                                  textCapitalization: TextCapitalization.none,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => _clearErrors(),
                                  onSubmitted: (_) => _handlePasswordSignIn(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: inputFontSize,
                                    color: const Color(0xFF18314F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    hintText: 'Enter password',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF64748B),
                                      fontSize: inputFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF18314F),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: inputPaddingV,
                                      horizontal: 14,
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
                                    PiggyToast.showInfo(
                                      context,
                                      'Please contact the Admin to reset your password.',
                                      title: 'Password Reset',
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
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
                                      : () => _handlePasswordSignIn(),
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
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Sign In',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                            height: 1.15,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divider with "or continue with"
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      'or continue with',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
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
                                height: buttonHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(27.0),
                                  border: Border.all(
                                    color: const Color(0xFF747775),
                                    width: 1.0,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isGoogleLoading
                                      ? null
                                      : () => _handleGoogleSignIn(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1F1F1F),
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(27.0),
                                    ),
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.center,
                                  ),
                                  child: _isGoogleLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF18314F),
                                                ),
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SvgPicture.string(
                                              googleLogoSvg,
                                              height: 20.0,
                                              width: 20.0,
                                            ),
                                            const SizedBox(width: 10.0),
                                            Text(
                                              'Continue with Google',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF1F1F1F,
                                                    ),
                                                    letterSpacing: 0.1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: fieldSpacing * 1.5),

                        // Bottom Navigation Link: "Don't have an account? Sign Up"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/signup',
                                    arguments: _targetRole,
                                  );
                                },
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fieldSpacing),
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
