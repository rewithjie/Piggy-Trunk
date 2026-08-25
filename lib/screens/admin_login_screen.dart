import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/piggy_trunk_logo.dart';
import '../styles/login_styles.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _loginBg = Colors.white;
  static const Color _brandPanelBg = Color(0xFFE0E6EF);
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _actionColor = Color(0xFF46597A);

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;

  late final AnimationController _logoController;
  late final Animation<double> _logoFloatAnimation;

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hasAuthCredentialError = false;
  String? _errorMessage;
  String? _successMessage;
  String? _emailError;
  String? _passwordError;

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _logoFloatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOutSine,
      ),
    );

    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadRememberedCredentials();

    // Auto-redirect if session already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  Future<void> _loadRememberedCredentials() async {
    final credentials = await _authService.getRememberedCredentials();
    final savedEmail = credentials['email'] as String? ?? '';
    final rememberMeStatus = credentials['rememberMe'] as bool? ?? false;

    if (mounted && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = rememberMeStatus;
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearMessages() {
    if (_errorMessage != null ||
        _successMessage != null ||
        _emailError != null ||
        _passwordError != null ||
        _hasAuthCredentialError) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
        _emailError = null;
        _passwordError = null;
        _hasAuthCredentialError = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    _clearMessages();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = 'Please enter your email or username.';
    } else if (!email.contains('@') && (email.contains('.') || RegExp(r'\.[a-zA-Z]{2,}$').hasMatch(email))) {
      emailErr = "Please include an '@' in the email address (e.g. admin@piggytrunk.com).";
    } else if (email.contains('@')) {
      if (email.startsWith('@')) {
        emailErr = "Please enter the part before '@'.";
      } else if (email.endsWith('@')) {
        emailErr = "Please enter a domain after '@' (e.g. piggytrunk.com).";
      } else if (!email.split('@').last.contains('.')) {
        emailErr = "Please enter a complete domain after '@' (e.g. piggytrunk.com).";
      } else {
        final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
        if (!emailRegex.hasMatch(email)) {
          emailErr = 'Please enter a valid email address.';
        }
      }
    } else if (email.length < 3) {
      emailErr = 'Username must be at least 3 characters.';
    }

    if (password.isEmpty) {
      passwordErr = 'Please enter your password.';
    } else if (password.length < 6) {
      passwordErr = 'Password must be at least 6 characters.';
    }

    if (emailErr != null || passwordErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passwordErr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );

      if (result['success']) {
        setState(() {
          _successMessage = result['message'] ?? 'Login successful!';
        });
        
        // Navigate to dashboard after short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        });
      } else {
        final msg = (result['message'] ?? 'Invalid email/username or password. Please check your credentials.').toString();
        if (result['errorField'] == 'email') {
          setState(() {
            _emailError = msg;
          });
        } else if (result['errorField'] == 'password') {
          setState(() {
            _passwordError = msg;
          });
        } else {
          setState(() {
            _hasAuthCredentialError = true;
            _passwordError = msg;
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasAuthCredentialError = true;
        _passwordError = 'Invalid email/username or password. Please check your credentials.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1120;

    return Scaffold(
      backgroundColor: isMobile ? _brandPanelBg : _loginBg,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout()
            : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildFormPanel(),
        ),
        Expanded(
          child: _buildBrandPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _brandPanelBg,
                    Color(0xFFEDF2F7),
                    Colors.white,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Brand Header for Mobile (Mobile-style Levitation & Shadow)
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      final floatY = _logoController.isAnimating ? _logoFloatAnimation.value * 0.7 : 0.0;
                      final double t = ((floatY + 5.6) / 11.2).clamp(0.0, 1.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, floatY),
                            child: const PiggyTrunkLogo(
                              size: 96,
                              withBorder: false,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Mobile Photorealistic Ambient Floor Shadow
                          Opacity(
                            opacity: (0.16 + 0.14 * t).clamp(0.08, 0.40),
                            child: Transform.scale(
                              scaleX: 0.88 + 0.24 * (1.0 - t),
                              scaleY: 0.85 + 0.20 * (1.0 - t),
                              child: Container(
                                width: 80,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _brandColor.withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.all(Radius.elliptical(80, 12)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _brandColor.withValues(alpha: 0.30),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Piggy Trunk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _brandColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 3.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: _actionColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Elevated White Login Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF18314F).withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Admin Login',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _brandColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your credentials to access the dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        if (_successMessage != null) ...[
                          _buildAlert(_successMessage!, isError: false),
                          const SizedBox(height: 18),
                        ],
                        _buildLoginForm(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: _loginBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTitle(),
                const SizedBox(height: 24),
                if (_successMessage != null) ...[
                  _buildAlert(_successMessage!, isError: false),
                  const SizedBox(height: 24),
                ],
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Admin Login',
      style: LoginStyles.titleStyle(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAlert(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: isError
          ? LoginStyles.errorAlertDecoration()
          : LoginStyles.successAlertDecoration(),
      child: Text(
        message,
        style: LoginStyles.alertTextStyle.copyWith(
          color: isError ? LoginStyles.errorText : LoginStyles.successText,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_isLoading) {
            _handleLogin();
          }
        },
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 18),
            _buildFormMeta(),
            const SizedBox(height: 29),
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EMAIL OR USERNAME',
          style: LoginStyles.labelStyle,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          textAlignVertical: TextAlignVertical.center,
          cursorHeight: 18,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: LoginStyles.brandText,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          decoration: LoginStyles.emailFieldDecoration(
            hintText: 'admin@piggytrunk.com or username',
            hasError: _emailError != null || _hasAuthCredentialError,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: LoginStyles.fieldIconColor,
            ),
          ),
          onFieldSubmitted: (_) {
            if (_passwordController.text.isEmpty) {
              _passwordFocus.requestFocus();
            } else if (!_isLoading) {
              _handleLogin();
            }
          },
          onChanged: (_) {
            if (_emailError != null || _passwordError != null || _hasAuthCredentialError) {
              _clearMessages();
            }
          },
        ),
        if (_emailError != null) LoginStyles.buildInlineError(_emailError!),
      ],
    );
  }

  Widget _buildPasswordField() {
    final bool isPasswordEmpty = _passwordController.text.isEmpty;
    final TextStyle fieldStyle = isPasswordEmpty
        ? GoogleFonts.poppins(
            fontSize: 15,
            color: LoginStyles.brandText,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.0,
            height: 1.2,
          )
        : (_isPasswordVisible
            ? GoogleFonts.poppins(
                fontSize: 15,
                color: LoginStyles.brandText,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.0,
                height: 1.2,
              )
            : GoogleFonts.poppins(
                fontSize: 18,
                color: LoginStyles.brandText,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                height: 1.2,
              ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASSWORD',
          style: LoginStyles.labelStyle,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          enabled: !_isLoading,
          obscureText: !_isPasswordVisible,
          obscuringCharacter: '•',
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.done,
          cursorHeight: 18,
          style: fieldStyle,
          decoration: LoginStyles.passwordFieldDecoration(
            hintText: 'Enter your password',
            hasError: _passwordError != null || _hasAuthCredentialError,
            suffixIcon: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: LoginStyles.visibilityIconSize,
                    color: _isPasswordVisible
                        ? LoginStyles.fieldIconColorActive
                        : LoginStyles.fieldIconColor,
                  ),
                ),
              ),
            ),
          ),
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _handleLogin();
            }
          },
          onChanged: (_) {
            if (_emailError != null || _passwordError != null || _hasAuthCredentialError) {
              _clearMessages();
            }
          },
        ),
        if (_passwordError != null) LoginStyles.buildInlineError(_passwordError!),
      ],
    );
  }

  Widget _buildFormMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildRememberCheckbox(),
        _buildForgotPasswordLink(),
      ],
    );
  }

  Widget _buildRememberCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: const BorderSide(
              color: LoginStyles.checkboxColor,
              width: 1.4,
            ),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _actionColor;
              }
              return Colors.white;
            }),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Remember this device',
          style: TextStyle(
            fontSize: 12,
            color: LoginStyles.labelText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Navigate to forgot password screen
          // Navigator.pushNamed(context, '/forgot-password');
        },
        child: Text(
          'FORGOT PASSWORD?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: LoginStyles.labelText,
            letterSpacing: 0,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _actionColor,
          disabledBackgroundColor: _actionColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'SIGN IN TO DASHBOARD',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _brandPanelBg,
            _brandPanelBg,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBrandLogoCard(),
                const SizedBox(height: 32),
                _buildBrandTitle(),
                const SizedBox(height: 16),
                _buildBrandDivider(),
                const SizedBox(height: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogoCard() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final floatY = _logoController.isAnimating ? _logoFloatAnimation.value : 0.0;
        // Normalized t: 0.0 when top (-8px), 1.0 when bottom (+8px)
        final double t = ((floatY + 8.0) / 16.0).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Levitating Enlarged Logo
            Transform.translate(
              offset: Offset(0, floatY),
              child: const PiggyTrunkLogo(
                size: LogoSize.hero,
                withBorder: false,
              ),
            ),
            const SizedBox(height: 14),
            // Photorealistic Soft Ambient Floor Shadow (Matching Mobile App)
            Opacity(
              opacity: (0.18 + 0.16 * t).clamp(0.08, 0.45),
              child: Transform.scale(
                scaleX: 0.88 + 0.24 * (1.0 - t),
                scaleY: 0.85 + 0.20 * (1.0 - t),
                child: Container(
                  width: 135,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.all(Radius.elliptical(135, 18)),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrandTitle() {
    return Center(
      child: Text(
        'Piggy Trunk',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04,
              color: _brandColor,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBrandDivider() {
    return Center(
      child: Container(
        width: 118,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _actionColor,
        ),
      ),
    );
  }
}
