import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../providers/admin_profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profilePictureUrl;
  String? _profilePicturePath;
  bool _isUploadingImage = false;
  bool _isSavingProfile = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Theme-aware color getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _surfaceDark => _isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
  Color get _borderDark => _isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
  Color get _textDark => _isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
  Color get _primaryDark => _isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;

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
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        final metadata = user.userMetadata ?? <String, dynamic>{};
        final currentProfile = ref.read(adminProfileProvider);
        final savedName = (metadata['admin_name'] ?? '').toString().trim();
        final savedRole = (metadata['role'] ?? '').toString().trim();
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
              : (currentProfile.adminName.trim().isNotEmpty ? currentProfile.adminName : 'Admin');
          _roleController.text = savedRole.isNotEmpty
              ? savedRole
              : (currentProfile.role.trim().isNotEmpty ? currentProfile.role : 'System Administrator');
          _profilePicturePath = savedPhotoPath.isNotEmpty ? savedPhotoPath : _profilePicturePath;
          _profilePictureUrl = resolvedPhotoUrl ?? currentProfile.profilePictureUrl;
        });

        ref.read(adminProfileProvider.notifier).updateProfile(
              adminName: _adminNameController.text,
              email: user.email!,
              role: _roleController.text,
              profilePictureUrl: _profilePictureUrl,
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
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(

        children: [
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: _surfaceDark.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(26),
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
                                      return Icon(
                                        Icons.person_outline,
                                        color: _textDark,
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  color: _textDark,
                                  size: 40,
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
                          color: _primaryDark.withOpacity(0.1),
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
          _textField(_adminNameController),
          const SizedBox(height: 12),
          _textFieldLabel('Email'),
          _readOnlyTextField(_emailController),
          const SizedBox(height: 12),
          _textFieldLabel('Role'),
          _textField(_roleController),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _surfaceDark.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Access',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  'ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: 0.08,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
        color: _surfaceDark.withOpacity(0.75),
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
          ),
          const SizedBox(height: 12),
          _textFieldLabel('New Password'),
          _passwordField(
            controller: _newPasswordController,
            hint: 'Enter new password',
            obscure: _obscureNewPassword,
            onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          const SizedBox(height: 12),
          _textFieldLabel('Confirm New Password'),
          _passwordField(
            controller: _confirmPasswordController,
            hint: 'Confirm new password',
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _solidButton('Change Password', onTap: _requestPasswordChange),
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
        color: _textDark.withOpacity(0.85),
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

  Widget _textField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _bgDark.withOpacity(0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryDark),
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
        fillColor: _bgDark.withOpacity(0.25),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
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
        fillColor: _bgDark.withOpacity(0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryDark),
        ),
      ),
    );
  }

  Future<void> _requestPasswordChange() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active admin session found.')),
      );
      return;
    }

    if (_newPasswordController.text.trim().isEmpty || _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and confirm the new password.')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password update is connected and ready, but not enabled yet. Coming soon.'),
      ),
    );
  }


  Widget _solidButton(String label, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionBg = isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary;
    final actionFg = isDark ? PiggyTrunkTheme.ptPrimary : PiggyTrunkTheme.ptSurface;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: actionBg,
        foregroundColor: actionFg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
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

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxHeight: 200,
        maxWidth: 200,
      );

      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (!kIsWeb) {
            _selectedImage = File(pickedFile.path);
          }
          _selectedImageBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected. Click Save Profile to apply changes.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final fileName = 'admin-profile-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'admin_profiles/$fileName';

      if (kIsWeb && _selectedImageBytes != null) {
        // Web: use bytes to upload
        await _supabase.storage.from('profile_pictures').uploadBinary(
          filePath,
          _selectedImageBytes!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      } else if (_selectedImage != null) {
        // Mobile: use file to upload
        await _supabase.storage.from('profile_pictures').upload(
          filePath,
          _selectedImage!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      }

      final publicUrl = _supabase.storage.from('profile_pictures').getPublicUrl(filePath);
      String displayUrl = publicUrl;
      try {
        displayUrl = await _supabase.storage
            .from('profile_pictures')
            .createSignedUrl(filePath, 60 * 60 * 24 * 30);
      } catch (_) {
        // If signed URL generation fails, fallback to public URL.
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        final existingMetadata = Map<String, dynamic>.from(user.userMetadata ?? <String, dynamic>{});
        existingMetadata['profile_picture_url'] = displayUrl;
        existingMetadata['profile_picture_path'] = filePath;
        await _supabase.auth.updateUser(
          UserAttributes(data: existingMetadata),
        );
      }

      if (mounted) {
        setState(() {
          _profilePicturePath = filePath;
          _profilePictureUrl = displayUrl;
          _selectedImageBytes = null; // Clear bytes after upload
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveAdminProfile() async {
    if (_selectedImage != null || _selectedImageBytes != null) {
      await _uploadProfileImage();
    }

    setState(() => _isSavingProfile = true);
    try {
      final user = _supabase.auth.currentUser;
      final Map<String, dynamic> metadataPayload = {
        'admin_name': _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
        'role': _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
      };
      if (_profilePictureUrl != null && _profilePictureUrl!.trim().isNotEmpty) {
        metadataPayload['profile_picture_url'] = _profilePictureUrl!.trim();
      }
      if (_profilePicturePath != null && _profilePicturePath!.trim().isNotEmpty) {
        metadataPayload['profile_picture_path'] = _profilePicturePath!.trim();
      }

      if (user != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: metadataPayload,
          ),
        );
      }

      // Update the admin profile provider
      ref.read(adminProfileProvider.notifier).updateProfile(
            adminName: _adminNameController.text.trim().isEmpty ? 'Admin' : _adminNameController.text.trim(),
            email: _emailController.text,
            role: _roleController.text.trim().isEmpty ? 'System Administrator' : _roleController.text.trim(),
            profilePictureUrl: _profilePictureUrl,
          );

      await _loadAdminProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _selectedImage = null; // Clear selected image after save
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  void _resetForm() {
    _adminNameController.text = 'Admin';
    _roleController.text = 'System Administrator';
    ref.read(adminProfileProvider.notifier).updateProfile(
          adminName: 'Admin',
          role: 'System Administrator',
          email: _emailController.text.trim(),
          profilePictureUrl: _profilePictureUrl,
        );
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _obscureCurrentPassword = true;
      _obscureNewPassword = true;
      _obscureConfirmPassword = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form reset to default admin values.')),
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
}
