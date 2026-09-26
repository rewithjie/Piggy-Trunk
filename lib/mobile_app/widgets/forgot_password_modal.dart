import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/services/email_service.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'piggy_toast.dart';

class ForgotPasswordModal extends StatefulWidget {
  final String initialEmail;
  final Function(String email)? onPasswordResetSuccess;

  const ForgotPasswordModal({
    super.key,
    this.initialEmail = '',
    this.onPasswordResetSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    Function(String email)? onPasswordResetSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordModal(
        initialEmail: initialEmail,
        onPasswordResetSuccess: onPasswordResetSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  late TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _step = 1; // 1: Send OTP, 2: Verify & Reset
  String _targetEmail = '';
  String? _localGeneratedOtp;
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmailFormat(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(cleaned);
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !_isValidEmailFormat(email)) {
      setState(() => _errorMessage = 'Please enter a valid Gmail / email address (e.g. name@gmail.com).');
      return;
    }

    if (email == 'admin' ||
        email == 'admin@piggytrunk.com' ||
        email == 'admin@gmail.com' ||
        email == 'piggytrunk@gmail.com') {
      setState(() => _errorMessage =
          'The default system account ($email) cannot receive reset codes. Please enter your personal registered Gmail address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final generatedOtp = (100000 + Random().nextInt(900000)).toString();

      // 1. Register OTP in Supabase via RPC
      bool registeredInDb = false;
      try {
        dynamic rpcRes;
        try {
          rpcRes = await Supabase.instance.client.rpc(
            'user_request_password_reset_otp',
            params: {
              'target_email': email,
              'otp_code': generatedOtp,
            },
          );
        } catch (_) {
          // Fallback to admin RPC if user RPC is not yet loaded
          rpcRes = await Supabase.instance.client.rpc(
            'admin_request_password_reset_otp',
            params: {
              'target_email': email,
              'otp_code': generatedOtp,
            },
          );
        }

        if (rpcRes != null && (rpcRes['success'] == true || rpcRes['success'] == 'true')) {
          registeredInDb = true;
        } else if (rpcRes != null && rpcRes['message'] != null) {
          if (mounted) {
            setState(() {
              _errorMessage = rpcRes['message'].toString();
              _isLoading = false;
            });
          }
          return;
        }
      } catch (rpcErr) {
        debugPrint('RPC error: $rpcErr');
      }

      // Fallback check if RPC function not found or failed, and retrieve user's name & role
      String? matchedUserName;
      String? matchedUserRole;
      try {
        final existingUser = await Supabase.instance.client
            .from('app_users')
            .select('user_id, email, name, role')
            .eq('email', email)
            .maybeSingle();

        if (existingUser != null) {
          matchedUserName = existingUser['name']?.toString();
          matchedUserRole = existingUser['role']?.toString();
        } else if (!registeredInDb) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'No registered account found with email "$email". Please check your spelling or sign in with your credentials.';
              _isLoading = false;
            });
          }
          return;
        }

        if (!registeredInDb) {
          await Supabase.instance.client.from('admin_password_resets').insert({
            'email': email,
            'otp_code': generatedOtp,
            'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
            'used': false,
          });
          registeredInDb = true;
        }
      } catch (dbErr) {
        debugPrint('User profile check notice: $dbErr');
        if (!registeredInDb && mounted) {
          setState(() {
            _errorMessage = 'Account verification failed: $dbErr';
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Dispatch OTP via Gmail SMTP
      final emailSent = await EmailService().sendPasswordResetOtpEmail(
        recipientEmail: email,
        otpCode: generatedOtp,
        recipientName: matchedUserName,
        userRole: matchedUserRole,
        isAdmin: false,
      );

      if (!emailSent) {
        // In local development / testing, allow proceeding to Step 2 with the generated OTP
        if (kDebugMode && mounted) {
          debugPrint('[DEV OTP] Password reset verification code: $generatedOtp');
          setState(() {
            _targetEmail = email;
            _localGeneratedOtp = generatedOtp;
            _step = 2;
            _isLoading = false;
            _errorMessage = null;
          });
          PiggyToast.show(
            context,
            message: '[Dev Mode] Your OTP code is $generatedOtp',
            type: ToastType.info,
          );
          return;
        }

        if (mounted) {
          setState(() {
            _errorMessage =
                'Unable to send verification email. Please check your internet connection or try again shortly.';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _targetEmail = email;
          _localGeneratedOtp = generatedOtp;
          _step = 2;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate reset code: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final enteredOtp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool resetSuccess = false;
      String? failMsg;

      // 1. Try RPC reset (prefer user-specific RPC to avoid misleading admin notifications)
      try {
        dynamic rpcRes;
        try {
          rpcRes = await Supabase.instance.client.rpc(
            'user_verify_otp_and_reset_password',
            params: {
              'target_email': _targetEmail,
              'otp_code': enteredOtp,
              'new_password': newPass,
            },
          );
        } catch (_) {
          // Fallback to legacy RPC if user RPC is not yet executed in Supabase DB
          rpcRes = await Supabase.instance.client.rpc(
            'admin_verify_otp_and_reset_password',
            params: {
              'target_email': _targetEmail,
              'otp_code': enteredOtp,
              'new_password': newPass,
            },
          );
        }

        if (rpcRes != null && (rpcRes['success'] == true || rpcRes['success'] == 'true')) {
          resetSuccess = true;
        } else if (rpcRes != null && rpcRes['message'] != null) {
          failMsg = rpcRes['message'].toString();
        }
      } catch (rpcErr) {
        debugPrint('Mobile reset RPC notice: $rpcErr');
      }

      // 2. Fallback check if local OTP matches
      if (!resetSuccess && failMsg == null) {
        if (_localGeneratedOtp != null && enteredOtp == _localGeneratedOtp) {
          try {
            await Supabase.instance.client.auth.updateUser(
              UserAttributes(password: newPass),
            );
            resetSuccess = true;
          } catch (_) {}
        }
      }

      if (resetSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onPasswordResetSuccess?.call(_targetEmail);
          PiggyToast.showSuccess(
            context,
            'Password reset successfully! You can now log in with your new password.',
            title: 'Password Updated',
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = failMsg ??
                'Invalid or expired code. Please make sure database functions (31_admin_auth_recovery_functions.sql) are executed in Supabase.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final subtitleColor = isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF64748B);
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: keyboardBottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Pill
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                if (_step == 2) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: titleColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _isLoading ? null : () => setState(() => _step = 1),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18314F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _step == 1 ? Icons.lock_reset_rounded : Icons.mark_email_read_rounded,
                    color: const Color(0xFF18314F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _step == 1 ? 'Forgot Password' : 'Verify Code & Set Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              _step == 1
                  ? 'Enter your registered Gmail or email address. We will send you a 6-digit verification code to reset your password.'
                  : 'Enter the 6-digit verification code sent to $_targetEmail and choose your new password.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: subtitleColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            if (_step == 1) ...[
              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  labelText: 'Gmail / Email Address',
                  hintText: 'e.g. raiser@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF18314F)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF18314F), width: 1.6),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
            ] else ...[
              // OTP Input
              Text(
                '6-Digit Verification Code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: GoogleFonts.sourceCodePro(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF18314F),
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: GoogleFonts.sourceCodePro(
                    fontSize: 24,
                    letterSpacing: 8,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF18314F), width: 1.6),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              // New Password
              Text(
                'New Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPass,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              // Confirm New Password
              Text(
                'Confirm New Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPass,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Re-enter your new password',
                  prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_step == 1 ? _handleSendOtp : _handleVerifyAndReset),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18314F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(
                        _step == 1 ? 'Send Reset Code' : 'Reset Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
