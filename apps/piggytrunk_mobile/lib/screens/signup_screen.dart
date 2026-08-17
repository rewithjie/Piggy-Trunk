import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/services/email_service.dart';
import '../services/google_auth_service.dart';
import '../utils/screen_fit_util.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_fullNameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        _errorMessage != null) {
      setState(() {
        _fullNameError = null;
        _emailError = null;
        _passwordError = null;
        _confirmPasswordError = null;
        _errorMessage = null;
      });
    }
  }

  String _getFriendlyAuthErrorMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user_already_exists')) {
      return 'May umiiral nang account sa email na ito. Mangyaring mag-login o gumamit ng ibang email.';
    } else if (lower.contains('password should be at least')) {
      return 'Ang password ay dapat hindi bababa sa 6 na karakter.';
    } else if (lower.contains('network') ||
        lower.contains('socketexception') ||
        lower.contains('connection')) {
      return 'Hindi makakonekta sa internet. Mangyaring suriin ang iyong koneksyon.';
    }
    return 'Nagkaroon ng problema sa pag-rehistro. Mangyaring subukang muli.';
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

  Future<void> _handlePasswordSignUp(String targetRole) async {
    _clearErrors();

    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confirmPassErr;

    // 1. Full Name Validation
    if (fullName.isEmpty) {
      nameErr = 'Mangyaring ilagay ang iyong buong pangalan.';
    }

    // 2. Email Validation (Strict for '@' and 'gmail.com')
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) {
      emailErr = 'Mangyaring ilagay ang iyong Gmail address.';
    } else if (!cleanEmail.contains('@')) {
      emailErr = 'Kulang ng "@" ang email address (hal. name@gmail.com).';
    } else if (!cleanEmail.contains('gmail')) {
      emailErr = 'Kailangang Gmail account ang gamitin (hal. name@gmail.com).';
    } else if (!cleanEmail.endsWith('@gmail.com')) {
      emailErr = 'Dapat magtapos sa "@gmail.com" ang email address.';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(cleanEmail)) {
      emailErr = 'Maglagay ng wastong Gmail address (hal. name@gmail.com).';
    }

    // 3. Password Validation
    if (password.isEmpty) {
      passErr = 'Mangyaring maglagay ng password.';
    } else if (password.length < 6) {
      passErr = 'Ang password ay dapat hindi bababa sa 6 na karakter.';
    }

    // 4. Confirm Password Validation
    if (confirmPassword.isEmpty) {
      confirmPassErr = 'Mangyaring kumpirmahin ang iyong password.';
    } else if (password != confirmPassword) {
      confirmPassErr = 'Hindi magkatugma ang Password at Kumpirmahin ang Password.';
    }

    if (nameErr != null || emailErr != null || passErr != null || confirmPassErr != null) {
      setState(() {
        _fullNameError = nameErr;
        _emailError = emailErr;
        _passwordError = passErr;
        _confirmPasswordError = confirmPassErr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String resolvedName = fullName.isEmpty
          ? email.split('@').first
          : fullName;

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': resolvedName,
          'name': resolvedName,
          'role': targetRole,
        },
      );

      final user = response.user;
      if (user != null) {
        dynamic newUserId;
        try {
          final insertedUser = await Supabase.instance.client.from('app_users').upsert({
            'supabase_user_id': user.id,
            'email': email,
            'name': resolvedName,
            'role': targetRole,
            'status': 'Pending',
          }, onConflict: 'email').select('user_id').single();
          newUserId = insertedUser['user_id'];
        } catch (_) {
          final fetched = await Supabase.instance.client
              .from('app_users')
              .select('user_id')
              .eq('email', email)
              .maybeSingle();
          newUserId = fetched?['user_id'];
        }

        if (newUserId != null) {
          if (targetRole == 'hog_raiser' || targetRole == 'raiser') {
            try {
              await Supabase.instance.client.from('hog_raisers').insert({
                'user_id': newUserId,
                'name': resolvedName,
                'phone': 'N/A',
                'address': 'N/A',
                'status': 'Inactive',
                'account_status': 'Pending',
                'pig_type': 'N/A',
                'lifecycle_stage': 'N/A',
              });
            } catch (e) {
              debugPrint('Hog raiser auto-create notice: $e');
            }
          } else if (targetRole == 'partner') {
            try {
              await Supabase.instance.client.from('partner_investors').insert({
                'user_id': newUserId,
                'status': 'Pending',
              });
            } catch (e) {
              debugPrint('Partner investor auto-create notice: $e');
            }
          } else if (targetRole == 'cashier') {
            try {
              await Supabase.instance.client.from('cashiers').insert({
                'user_id': newUserId,
                'status': 'Pending',
              });
            } catch (e) {
              debugPrint('Cashier auto-create notice: $e');
            }
          }

          // Send Welcome Registration Email to User via Resend
          try {
            EmailService().sendRegistrationEmail(
              recipientEmail: email,
              recipientName: resolvedName,
              role: targetRole,
            );
          } catch (e) {
            debugPrint('Registration email dispatch notice: $e');
          }

          // Explicitly sync admin notification with exact targetRole
          try {
            final String roleDisplay = targetRole == 'hog_raiser' || targetRole == 'raiser'
                ? 'Hog Raiser'
                : targetRole == 'partner'
                    ? 'Partner Investor'
                    : targetRole == 'cashier'
                        ? 'Cashier'
                        : 'User';
            await Supabase.instance.client
                .from('admin_notifications')
                .delete()
                .eq('metadata->>email', email)
                .eq('type', 'user_registration');
            await Supabase.instance.client.from('admin_notifications').insert({
              'title': 'New User Registration',
              'message': '$resolvedName ($email) registered as $roleDisplay and is pending approval.',
              'type': 'user_registration',
              'is_read': false,
              'metadata': {
                'user_id': newUserId,
                'name': resolvedName,
                'email': email,
                'role': targetRole,
              },
            });
          } catch (_) {}
        }

        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
                'Matagumpay na nairehistro ang iyong account! Kasalukuyan pa itong naghihintay ng pag-apruba mula sa Admin bago ka makapasok.',
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/login',
                        arguments: targetRole,
                      );
                    },
                    child: const Text(
                      'Mag-Login',
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
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getFriendlyAuthErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Nagkaroon ng problema sa pag-rehistro. Mangyaring subukang muli.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp(String targetRole) async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle(
        targetRole: targetRole,
        isSignUpMode: true,
      );

      if (result['success'] == true) {
        final String rawStatus = (result['status'] ?? 'Pending').toString();
        final String statusLower = rawStatus.toLowerCase();
        final String role = (result['role'] ?? targetRole).toString();

        if (statusLower == 'pending') {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
                  'Matagumpay na na-link ang iyong Google account!\n\nKasalukuyan pa itong naghihintay ng pag-apruba mula sa Admin bago ka makapasok.',
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
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        Navigator.pushReplacementNamed(
                          context,
                          '/login',
                          arguments: role,
                        );
                      },
                      child: const Text(
                        'Mag-Login',
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
        } else if (statusLower == 'active') {
          if (mounted) {
            if (role == 'hog_raiser') {
              Navigator.pushReplacementNamed(context, '/raiser_dashboard');
            } else if (role == 'cashier') {
              Navigator.pushReplacementNamed(context, '/cashier_dashboard');
            } else if (role == 'partner') {
              Navigator.pushReplacementNamed(context, '/partner_dashboard');
            }
          }
        }
      } else if (result['message'] != null &&
          result['message'] != 'Canceled Google sign-in.') {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sa Google Sign-Up: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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

                          // Action Title "Gumawa ng Account"
                          Text(
                            'Gumawa ng Account',
                            style: TextStyle(
                              fontSize: titleFontSize - 1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF18314F),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle: Mag-rehistro bilang Hog Raiser
                          Text(
                            'Mag-rehistro bilang $displayRole',
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
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: const Color(0xFFC62828),
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: fieldSpacing),
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
                              // Full Name Label
                              Text(
                                'Buong Pangalan',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Full Name Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _fullNameError != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFFCBD5E1),
                                    width: _fullNameError != null ? 1.5 : 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _fullNameController,
                                  style: TextStyle(
                                    fontSize: inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18314F),
                                  ),
                                  onChanged: (_) {
                                    if (_fullNameError != null) {
                                      setState(() => _fullNameError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: inputPaddingV,
                                    ),
                                    border: InputBorder.none,
                                    hintText: 'hal. Juan Dela Cruz',
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
                              _buildInlineError(_fullNameError),
                              SizedBox(height: fieldSpacing),

                              // Username / Email Label
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Username / Email Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _emailError != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFFCBD5E1),
                                    width: _emailError != null ? 1.5 : 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    fontSize: inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18314F),
                                  ),
                                  onChanged: (_) {
                                    if (_emailError != null) {
                                      setState(() => _emailError = null);
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
                                      Icons.email_outlined,
                                      color: Color(0xFF64748B),
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                              _buildInlineError(_emailError),
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
                                    hintText: 'Gumawa ng iyong password',
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
                              SizedBox(height: fieldSpacing),

                              // Confirm Password Label
                              Text(
                                'Kumpirmahin ang Password',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18314F),
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Confirm Password Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _confirmPasswordError != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFFCBD5E1),
                                    width: _confirmPasswordError != null ? 1.5 : 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: TextStyle(
                                    fontSize: inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18314F),
                                  ),
                                  onChanged: (_) {
                                    if (_confirmPasswordError != null) {
                                      setState(() => _confirmPasswordError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: inputPaddingV,
                                    ),
                                    border: InputBorder.none,
                                    hintText: 'Ulitin ang iyong password',
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
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: const Color(0xFF64748B),
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildInlineError(_confirmPasswordError),
                              SizedBox(height: fieldSpacing * 1.3),

                              // Sign Up Button (Piggy Brand Navy Gradient without check icon)
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
                                      : () => _handlePasswordSignUp(role),
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
                                          'Gumawa ng Account',
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

                              // Sign up with Google Button (Official Google Sign-In Pill Style)
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
                                      : () => _handleGoogleSignUp(role),
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
                                              'Mag-Sign up gamit ang Google',
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

                              // Already have an account Link (Aligned color + Underline)
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
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
                                          text: 'May account ka na ba? ',
                                        ),
                                        TextSpan(
                                          text: 'Mag-Sign In Dito',
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
