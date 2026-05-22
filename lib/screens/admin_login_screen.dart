import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/piggy_trunk_logo.dart';
import '../styles/login_styles.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

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

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
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
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    _clearMessages();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
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
      backgroundColor: Colors.transparent,
      body: Container(
        color: _loginBg,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormPanel(),
        ],
      ),
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
                if (_errorMessage != null) ...[
                  _buildAlert(_errorMessage!, isError: true),
                  const SizedBox(height: 24),
                ],
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

  Widget _buildSubtitle() {
    return const Text(
      'Manage your PiggyTrunk admin dashboard with secure access',
      textAlign: TextAlign.center,
      style: LoginStyles.subtitleStyle,
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
          const SizedBox(height: 23),
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
          'EMAIL ADDRESS',
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
            hintText: 'admin@piggytrunk',
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: LoginStyles.fieldIconColor,
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Email is required';
            }
            // Simple email validation - just check for @ symbol
            if (!value!.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onChanged: (_) => _clearMessages(),
        ),
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
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Password is required';
            }
            if (value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onChanged: (_) => _clearMessages(),
        ),
      ],
    );
  }

  Widget _buildFormMeta() {
    final isMobile = MediaQuery.of(context).size.width < 640;

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRememberCheckbox(),
              const SizedBox(height: 12),
              _buildForgotPasswordLink(),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(
            color: LoginStyles.checkboxColor,
            width: 1.4,
          ),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _actionColor;
            }
            return Colors.white;
          }),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text(
         'Remember this device',
          style: TextStyle(
            fontSize: 14,
            color: LoginStyles.labelText,
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LoginStyles.labelText,
            letterSpacing: 0.08,
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
          disabledBackgroundColor: _actionColor.withOpacity(0.6),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
