import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../providers/admin_profile_provider.dart';
import '../utils/responsive.dart';
import '../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  Uint8List? _selectedImageBytes;
  String? _profilePictureUrl;
  String? _profilePicturePath;
  bool _isUploadingImage = false;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _adminNameError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  // Theme-aware color getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _surfaceDark => _isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
  Color get _borderDark => _isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
  Color get _textDark => _isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
  Color get _primaryDark => _isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;

  Widget _buildInlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.5),
            child: Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53E3E)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53E3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _adminNameController =
      TextEditingController(text: 'Admin');
  final TextEditingController _emailController =
      TextEditingController(text: '');
  final TextEditingController _roleController =
      TextEditingController(text: 'System Administrator');
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final session = _supabase.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    if (isInitialLaunch) {
      isInitialLaunch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return;
    }
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final userResponse = await _supabase.auth.getUser();
      final user = userResponse.user;
      if (user != null && user.email != null) {
        // Query app_users table first to get saved database name and role
        String? dbName;
        String? dbRole;
        try {
          final res = await _supabase
              .from('app_users')
              .select('name, role')
              .eq('email', user.email!)
              .maybeSingle();
          if (res != null) {
            dbName = res['name']?.toString();
            dbRole = res['role']?.toString();
          }
        } catch (e) {
          debugPrint('Error loading profile from DB: $e');
        }

        final metadata = user.userMetadata ?? <String, dynamic>{};
        final currentProfile = ref.read(adminProfileProvider);

        // Fallbacks: DB Name -> user metadata (admin_name, full_name, name) -> Riverpod state -> Split Email -> 'Admin'
        final String fallbackEmailName = user.email!.split('@')[0];
        final String savedName = (dbName ?? 
            metadata['admin_name'] ?? 
            metadata['full_name'] ?? 
            metadata['name'] ?? 
            '').toString().trim();
        final String savedRole = (dbRole ?? metadata['role'] ?? '').toString().trim();

        final savedPhoto = (metadata['profile_picture_url'] ?? '').toString().trim();
        final savedPhotoPath = (metadata['profile_picture_path'] ?? '').toString().trim();
        String? resolvedPhotoUrl = savedPhoto.isNotEmpty ? savedPhoto : null;
        if (savedPhotoPath.isNotEmpty) {
          try {
            resolvedPhotoUrl = await _supabase.storage
                .from('profile_pictures')
                .createSignedUrl(savedPhotoPath, 60 * 60 * 24 * 30);
          } catch (_) {
            // Fall back to saved URL when signed URL cannot be created.
          }
        }

        setState(() {
          _emailController.text = user.email!;
          _adminNameController.text = savedName.isNotEmpty
              ? savedName
              : (currentProfile.adminName.trim().isNotEmpty ? currentProfile.adminName : fallbackEmailName);
          _roleController.text = savedRole.isNotEmpty
              ? savedRole
              : (currentProfile.role.trim().isNotEmpty ? currentProfile.role : 'System Administrator');
          _profilePicturePath = savedPhotoPath.isNotEmpty ? savedPhotoPath : null;
          _profilePictureUrl = resolvedPhotoUrl;
        });

        ref.read(adminProfileProvider.notifier).updateProfile(
              adminName: _adminNameController.text,
              email: user.email!,
              role: _roleController.text,
              profilePictureUrl: _profilePictureUrl,
              clearProfilePicture: _profilePictureUrl == null,
              isHydrated: true,
            );
      } else {
        final currentProfile = ref.read(adminProfileProvider);
        if (!mounted) return;
        setState(() {
          _emailController.text = currentProfile.email;
          _adminNameController.text =
              currentProfile.adminName.trim().isNotEmpty ? currentProfile.adminName : 'Admin';
          _roleController.text = currentProfile.role.trim().isNotEmpty
              ? currentProfile.role
              : 'System Administrator';
          _profilePictureUrl = currentProfile.profilePictureUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    }
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _surfaceDark,
              child: AdminSidebar(
                currentRoute: '/settings',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/settings',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: _surfaceDark.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
                        ),
                        padding: EdgeInsets.all(isMobile ? 14 : 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.03,
                              ),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isStacked = constraints.maxWidth < 1100;

                                if (isStacked) {
                                  return Column(
                                    children: [
                                      _buildAdminProfileCard(),
                                      const SizedBox(height: 16),
                                      _buildSecurityCard(),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildAdminProfileCard()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildSecurityCard()),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfileCard() {
    return _panelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ADMIN PROFILE'),
          const SizedBox(height: 6),
          Text(
            'Account Center',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 16),
          // Unified Profile Section with Upload
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryDark, width: 2),
                  ),
                  child: _isUploadingImage
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedImageBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profilePictureUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return ClipOval(
                                        child: Image.asset(
                                          'assets/piggytrunk_logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : ClipOval(
                                  child: Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mutedDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primaryDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _primaryDark, width: 1),
                        ),
                        child: Text(
                          'Upload Photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _primaryDark,
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _textFieldLabel('Admin Name'),
          _textField(
            _adminNameController,
            hasError: _adminNameError != null,
            onChanged: (_) {
              if (_adminNameError != null) setState(() => _adminNameError = null);
            },
          ),
          if (_adminNameError != null) _buildInlineError(_adminNameError!),
          const SizedBox(height: 12),
          _textFieldLabel('Email'),
          _readOnlyTextField(_emailController),
          const SizedBox(height: 12),
          _textFieldLabel('Role'),
          _textField(_roleController),
          const SizedBox(height: 20),
          Row(
            children: [
              _solidButton(
                _isSavingProfile ? 'Saving...' : 'Save Profile',
                onTap: _isSavingProfile ? null : _saveAdminProfile,
              ),
              const SizedBox(width: 10),
              _ghostButton('Reset', onTap: _resetForm),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  Widget _buildSecurityCard() {
    return _panelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SECURITY'),
          const SizedBox(height: 6),
          Text(
            'Change Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'For account protection, you can prepare a new password here.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mutedDark,
            ),
          ),
          const SizedBox(height: 14),
          _textFieldLabel('Current Password'),
          _passwordField(
            controller: _currentPasswordController,
            hint: 'Enter current password',
            obscure: _obscureCurrentPassword,
            onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
            hasError: _currentPasswordError != null,
            onChanged: (_) {
              if (_currentPasswordError != null) setState(() => _currentPasswordError = null);
            },
          ),
          if (_currentPasswordError != null) _buildInlineError(_currentPasswordError!),
          const SizedBox(height: 12),
          _textFieldLabel('New Password'),
          _passwordField(
            controller: _newPasswordController,
            hint: 'Enter new password',
            obscure: _obscureNewPassword,
            onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            hasError: _newPasswordError != null,
            onChanged: (_) {
              if (_newPasswordError != null) setState(() => _newPasswordError = null);
            },
          ),
          if (_newPasswordError != null) _buildInlineError(_newPasswordError!),
          const SizedBox(height: 12),
          _textFieldLabel('Confirm New Password'),
          _passwordField(
            controller: _confirmPasswordController,
            hint: 'Confirm new password',
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            hasError: _confirmPasswordError != null,
            onChanged: (_) {
              if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
            },
          ),
          if (_confirmPasswordError != null) _buildInlineError(_confirmPasswordError!),
          const SizedBox(height: 14),
          Row(
            children: [
              _solidButton(
                _isChangingPassword ? 'Updating Password...' : 'Change Password',
                onTap: _requestPasswordChange,
                isLoading: _isChangingPassword,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textDark.withValues(alpha: 0.85),
        letterSpacing: 0.08,
      ),
    );
  }

  Widget _textFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _bgDark.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _borderDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _borderDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _primaryDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _mutedDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _bgDark.withValues(alpha: 0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: _mutedDark,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _mutedDark,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: _bgDark.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _borderDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _borderDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE53E3E) : _primaryDark,
            width: hasError ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  Future<void> _requestPasswordChange() async {
    if (_isChangingPassword) return;

    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
      _showThemedSnackBar('No active admin session found.', backgroundColor: Colors.red);
      return;
    }

    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    String? currentErr;
    String? newErr;
    String? confirmErr;

    if (currentPass.isEmpty) {
      currentErr = 'Current password is required.';
    }

    if (newPass.isEmpty) {
      newErr = 'New password is required.';
    } else if (newPass.length < 6) {
      newErr = 'Password must be at least 6 characters.';
    } else if (newPass == currentPass) {
      newErr = 'New password must be different from current password.';
    }

    if (confirmPass.isEmpty) {
      confirmErr = 'Please confirm your new password.';
    } else if (newPass != confirmPass) {
      confirmErr = 'New password and confirmation do not match.';
    }

    if (currentErr != null || newErr != null || confirmErr != null) {
      setState(() {
        _currentPasswordError = currentErr;
        _newPasswordError = newErr;
        _confirmPasswordError = confirmErr;
      });
      return;
    }

    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _isChangingPassword = true;
    });

    try {
      // 1. Verify current password by signing in with Supabase Auth
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: currentPass,
        );
      } on AuthException catch (authErr) {
        final errText = authErr.message.toLowerCase();
        if (errText.contains('invalid') ||
            errText.contains('credential') ||
            errText.contains('password')) {
          if (!mounted) return;
          setState(() {
            _currentPasswordError = 'Incorrect current password. Please try again.';
            _isChangingPassword = false;
          });
          return;
        }
        rethrow;
      }

      // 2. Update to new password in Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );

      // 3. Clear inputs & show success notification
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      _showThemedSnackBar(
        'Password changed successfully!',
        backgroundColor: PiggyTrunkTheme.ptSuccess,
      );
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (!mounted) return;
      _showThemedSnackBar(
        'Failed to change password: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Widget _solidButton(String label, {VoidCallback? onTap, bool isLoading = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionBg = isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary;
    final actionFg = isDark ? PiggyTrunkTheme.ptPrimary : PiggyTrunkTheme.ptSurface;

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: actionBg,
        foregroundColor: actionFg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: actionFg,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxHeight: 400,
        maxWidth: 400,
      );

      if (pickedFile == null || !mounted) return;

      final bytes = await pickedFile.readAsBytes();
      
      // Instant visual feedback
      setState(() {
        _selectedImageBytes = bytes;
        _isUploadingImage = true;
      });

      final fileName = 'admin-profile-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'admin_profiles/$fileName';

      await _supabase.storage.from('profile_pictures').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _supabase.storage.from('profile_pictures').getPublicUrl(filePath);
      String displayUrl = publicUrl;
      try {
        displayUrl = await _supabase.storage
            .from('profile_pictures')
            .createSignedUrl(filePath, 60 * 60 * 24 * 30);
      } catch (_) {
        // Fallback to public URL
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        final existingMetadata = Map<String, dynamic>.from(user.userMetadata ?? <String, dynamic>{});
        existingMetadata['profile_picture_url'] = displayUrl;
        existingMetadata['profile_picture_path'] = filePath;
        await _supabase.auth.updateUser(
          UserAttributes(data: existingMetadata),
        );

        try {
          await _supabase.from('app_users').update({
            'profile_picture_url': displayUrl,
          }).eq('email', user.email!);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _profilePicturePath = filePath;
          _profilePictureUrl = displayUrl;
          _selectedImageBytes = null;
          _isUploadingImage = false;
        });

        // Update provider immediately so it syncs across top bars in real-time
        ref.read(adminProfileProvider.notifier).updateProfile(
              adminName: _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
              email: _emailController.text,
              role: _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
              profilePictureUrl: displayUrl,
              clearProfilePicture: false,
              isHydrated: true,
            );

        _showThemedSnackBar(
          'Profile picture updated successfully!',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        _showThemedSnackBar(
          'Error uploading image: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _saveAdminProfile() async {
    final name = _adminNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _adminNameError = 'Admin name is required.');
      return;
    }

    setState(() {
      _adminNameError = null;
      _isSavingProfile = true;
    });
    try {
      final user = _supabase.auth.currentUser;
      final Map<String, dynamic> metadataPayload = {
        'admin_name': _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
        'role': _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
        'profile_picture_url': (_profilePictureUrl != null && _profilePictureUrl!.trim().isNotEmpty) ? _profilePictureUrl!.trim() : '',
        'profile_picture_path': (_profilePicturePath != null && _profilePicturePath!.trim().isNotEmpty) ? _profilePicturePath!.trim() : '',
      };

      if (user != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: metadataPayload,
          ),
        );

        // Sync name and role to the public.app_users database table
        await _supabase.from('app_users').update({
          'name': _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
          'role': _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
        }).eq('email', user.email!);
      }

      // Update the admin profile provider
      ref.read(adminProfileProvider.notifier).updateProfile(
            adminName: _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
            email: _emailController.text,
            role: _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
            profilePictureUrl: _profilePictureUrl,
            clearProfilePicture: _profilePictureUrl == null,
            isHydrated: true,
          );

      await _loadAdminProfile();

      if (mounted) {
        _showThemedSnackBar(
          'Profile saved successfully!',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        );
        setState(() {
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showThemedSnackBar(
          'Error saving profile: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _resetForm() async {
    _adminNameController.text = 'Admin';
    _roleController.text = 'System Administrator';

    // Instant local state reset
    setState(() {
      _selectedImageBytes = null;
      _profilePictureUrl = null;
      _profilePicturePath = null;
      _adminNameError = null;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _obscureCurrentPassword = true;
      _obscureNewPassword = true;
      _obscureConfirmPassword = true;
    });

    // Instant provider update for top bar sync
    ref.read(adminProfileProvider.notifier).updateProfile(
          adminName: 'Admin',
          role: 'System Administrator',
          email: _emailController.text.trim(),
          profilePictureUrl: null,
          clearProfilePicture: true,
          isHydrated: true,
        );

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final Map<String, dynamic> metadataPayload = {
          'admin_name': 'Admin',
          'role': 'System Administrator',
          'profile_picture_url': '',
          'profile_picture_path': '',
        };
        await _supabase.auth.updateUser(
          UserAttributes(
            data: metadataPayload,
          ),
        );

        // Sync name and role to the public.app_users database table
        await _supabase.from('app_users').update({
          'name': 'Admin',
          'role': 'System Administrator',
        }).eq('email', user.email!);
      }
    } catch (e) {
      debugPrint('Error saving reset state: $e');
    }

    _showThemedSnackBar(
      'Form reset to default admin values.',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  Widget _ghostButton(String label, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghostFg = isDark ? _textDark : PiggyTrunkTheme.ptPrimary;
    final ghostBorder = isDark ? _borderDark : PiggyTrunkTheme.ptBorder;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ghostFg,
        side: BorderSide(color: ghostBorder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showThemedSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF315C8F),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
      ),
    );
  }
}
