import 'package:flutter/material.dart';
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

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const Color _loginBg = Colors.white;
  static const Color _brandPanelBg = Color(0xFFE0E6EF);
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _actionColor = Color(0xFF46597A);

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearMessages() {
    if (_errorMessage != null || _successMessage != null || _emailError != null || _passwordError != null) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
        _emailError = null;
        _passwordError = null;
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
        final msg = (result['message'] ?? 'Invalid email or password. Please check your credentials.').toString();
        setState(() {
          _passwordError = msg;
        });
      }
    } catch (e) {
      setState(() {
        _passwordError = 'Invalid email or password. Please check your credentials.';
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
                  // Top Brand Header for Mobile
                  PiggyTrunkLogo(
                    size: LogoSize.large,
                    withBorder: false,
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
    return Form(
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
          enabled: !_isLoading,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: LoginStyles.brandText,
            fontWeight: FontWeight.w500,
          ),
          decoration: LoginStyles.emailFieldDecoration(
            hintText: 'admin@piggytrunk.com or username',
            hasError: _emailError != null,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: LoginStyles.fieldIconColor,
            ),
          ),
          onChanged: (_) {
            if (_emailError != null || _passwordError != null) {
              _clearMessages();
            }
          },
        ),
        if (_emailError != null) LoginStyles.buildInlineError(_emailError!),
      ],
    );
  }

  Widget _buildPasswordField() {
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
          obscureText: !_isPasswordVisible,
          obscuringCharacter: '*',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: LoginStyles.brandText,
            fontWeight: FontWeight.w500,
          ),
          decoration: LoginStyles.passwordFieldDecoration(
            hintText: 'Enter your password',
            hasError: _passwordError != null,
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
          onChanged: (_) {
            if (_emailError != null || _passwordError != null) {
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
    return PiggyTrunkLogo(
      size: LogoSize.extraLarge,
      withBorder: false,
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
