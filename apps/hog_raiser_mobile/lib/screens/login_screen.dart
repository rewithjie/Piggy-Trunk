import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paki-fill up ang email at password.',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
      // 1. Sign in to Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 2. Fetch user status from public.app_users
        final userData = await Supabase.instance.client
            .from('app_users')
            .select('status, role')
            .eq('supabase_user_id', response.user!.id)
            .maybeSingle();

        if (userData == null) {
          // Fallback if record not yet synced
          await Supabase.instance.client.auth.signOut();
          throw const AuthException('Hindi nahanap ang profile sa system. Kontakin ang Admin.');
        }

        final status = userData['status'] as String;
        final role = userData['role'] as String;

        // Verify role is appropriate for this app
        if (role != 'hog_raiser' && role != 'admin') {
          await Supabase.instance.client.auth.signOut();
          throw const AuthException('Ang account na ito ay walang pahintulot bilang Hog Raiser.');
        }

        // 3. Handle Pending Status
        if (status == 'Pending') {
          // Sign out immediately
          await Supabase.instance.client.auth.signOut();
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Nakabinbing Account',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18314F)),
                ),
                content: const Text(
                  'Ang iyong account ay kasalukuyang sumasailalim sa approval ng Admin. Mangyaring maghintay bago mag-login.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Sige po', style: TextStyle(color: Color(0xFF2366CC))),
                  ),
                ],
              ),
            );
          }
        } else if (status == 'active') {
          // Proceed to dashboard on active status
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // Block suspended or inactive accounts
          await Supabase.instance.client.auth.signOut();
          throw AuthException('Ang iyong account ay may status na: $status. Kontakin ang Admin.');
        }
      }
    } on AuthException catch (e) {
      String tagalogMessage = e.message;
      final lowercaseMsg = e.message.toLowerCase();
      if (lowercaseMsg.contains('invalid login credentials') || 
          lowercaseMsg.contains('invalid credentials') || 
          lowercaseMsg.contains('user not found')) {
        tagalogMessage = 'Mali ang inyong email o password. Paki-check at subukan ulit.';
      } else if (lowercaseMsg.contains('email not confirmed')) {
        tagalogMessage = 'Hindi pa kumpirmado ang inyong email address. Paki-check ang inyong inbox.';
      } else if (lowercaseMsg.contains('rate limit')) {
        tagalogMessage = 'Masyadong maraming beses na sumubok. Mangyaring maghintay ng ilang sandali.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tagalogMessage,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button (aligned left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF18314F)),
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
                const SizedBox(height: 24),

                // Title & Subtitle (Centered)
                Text(
                  'Mag-Login',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(const Color(0xFF18314F)).copyWith(
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ilagay ang iyong detalye para magpatuloy sa iyong hog raiser dashboard.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(PiggyTrunkTheme.ptMuted),
                ),
                const SizedBox(height: 32),

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
                  style: AppTextStyles.body(const Color(0xFF18314F)).copyWith(
                    fontSize: 15,
                  ),
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
                      borderSide: const BorderSide(color: Color(0xFF18314F), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF5F6D81)),
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
                  style: AppTextStyles.body(const Color(0xFF18314F)).copyWith(
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang iyong password',
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
                      borderSide: const BorderSide(color: Color(0xFF18314F), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5F6D81)),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF5F6D81),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Nakalimutan ang Password?',
                      style: AppTextStyles.caption(const Color(0xFF2366CC)).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Mag-Patuloy',
                            style: AppTextStyles.button(Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Signup Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Wala pang account? ',
                      style: AppTextStyles.body(PiggyTrunkTheme.ptMuted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: Text(
                        'Mag-Sign Up',
                        style: AppTextStyles.bodyStrong(const Color(0xFF2366CC)),
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
