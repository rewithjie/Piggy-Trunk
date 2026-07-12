import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paki-fill up ang lahat ng field.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ang phone number ay dapat 11 digits.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ang password ay dapat hindi bababa sa 6 na characters.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Real Supabase signUp
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'hog_raiser',
          'full_name': name,
          'phone': phone,
          'address': address,
        },
      );

      if (response.user != null) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Nagawa na ang iyong Account!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18314F),
                  fontSize: 20,
                ),
              ),
              content: const Text(
                'Matagumpay na nagawa ang iyong account. Maghintay para sa approval ng Admin bago mag-login.',
                style: TextStyle(color: Color(0xFF5F6D81), fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    ); // Redirect to login
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color(0xFF2366CC),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        throw const AuthException(
          'Hindi nagawang i-create ang account. Subukan ulit.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auth Error [${e.statusCode}]: ${e.message}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button (aligned left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF18314F),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: PiggyTrunkTheme.ptSurface,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // PiggyTrunk Logo & Text Title (Centered)
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/piggytrunk_logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Piggy Trunk',
                        style: AppTextStyles.jakarta(
                          size: 22,
                          weight: FontWeight.w800,
                          color: const Color(0xFF18314F),
                          letterSpacing: -0.02,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle (Centered)
                Text(
                  'Mag-Sign Up',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gumawa ng bagong account para magsimula bilang Hog Raiser.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(PiggyTrunkTheme.ptMuted),
                ),
                const SizedBox(height: 32),

                // Full Name Input
                Text(
                  'Buong Pangalan',
                  style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  style: AppTextStyles.body(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang iyong buong pangalan',
                    hintStyle: AppTextStyles.body(const Color(0xFFB0BBCA)),
                    fillColor: const Color(0xFFE8EDF3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF18314F),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF5F6D81),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Number Input
                Text(
                  'Phone Number',
                  style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.body(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Hal. 09123456789',
                    hintStyle: AppTextStyles.body(const Color(0xFFB0BBCA)),
                    fillColor: const Color(0xFFE8EDF3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF18314F),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF5F6D81),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Address Input
                Text(
                  'Address',
                  style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  enabled: !_isLoading,
                  style: AppTextStyles.body(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang iyong kumpletong address',
                    hintStyle: AppTextStyles.body(const Color(0xFFB0BBCA)),
                    fillColor: const Color(0xFFE8EDF3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF18314F),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF5F6D81),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Input
                Text(
                  'Email Address',
                  style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.body(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang iyong email',
                    hintStyle: AppTextStyles.body(const Color(0xFFB0BBCA)),
                    fillColor: const Color(0xFFE8EDF3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF18314F),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF5F6D81),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Input
                Text(
                  'Password',
                  style: AppTextStyles.cardTitle(const Color(0xFF18314F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: !_isPasswordVisible,
                  style: AppTextStyles.body(
                    const Color(0xFF18314F),
                  ).copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Gumawa ng password',
                    hintStyle: AppTextStyles.body(const Color(0xFFB0BBCA)),
                    fillColor: const Color(0xFFE8EDF3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF18314F),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF5F6D81),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF5F6D81),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18314F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Mag-Register',
                            style: AppTextStyles.button(Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'May account ka na ba? ',
                      style: AppTextStyles.body(PiggyTrunkTheme.ptMuted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Mag-Login',
                        style: AppTextStyles.bodyStrong(
                          const Color(0xFF2366CC),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
