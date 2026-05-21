import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
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
  String _selectedTheme = 'Light / Dark Toggle';
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profilePictureUrl;
  bool _isUploadingImage = false;
  bool _isSavingProfile = false;
  String _adminEmail = '';

  // Theme-aware color getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _surfaceDark => _isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
  Color get _borderDark => _isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
  Color get _textDark => _isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
  Color get _primaryDark => _isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;

  final TextEditingController _appNameController =
      TextEditingController(text: 'PiggyTrunk Admin');

  final TextEditingController _adminNameController =
      TextEditingController(text: 'Admin');
  final TextEditingController _emailController =
      TextEditingController(text: '');
  final TextEditingController _roleController =
      TextEditingController(text: 'System Administrator');

  @override
  void initState() {
    super.initState();
    _loadAdminEmail();
  }

  Future<void> _loadAdminEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        setState(() {
          _adminEmail = user.email!;
          _emailController.text = user.email!;
        });
        // Update the provider with the email
        ref.read(adminProfileProvider.notifier).setEmail(user.email!);
      }
    } catch (e) {
      print('Error loading admin email: $e');
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
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
                                final isStacked = constraints.maxWidth < 1080;

                                if (isStacked) {
                                  return Column(
                                    children: [
                                      _buildAdminProfileCard(),
                                      const SizedBox(height: 18),
                                      _buildSystemPreferencesCard(),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 440,
                                      child: _buildAdminProfileCard(),
                                    ),
                                    const SizedBox(width: 22),
                                    Expanded(
                                      child: _buildSystemPreferencesCard(),
                                    ),
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
          const SizedBox(height: 20),
          // Unified Profile Section with Upload
          Row(
            children: [
              GestureDetector(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System Administrator',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mutedDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _textFieldLabel('Admin Name'),
          _textField(_adminNameController),
          const SizedBox(height: 12),
          _textFieldLabel('Email'),
          _readOnlyTextField(_emailController),
          const SizedBox(height: 12),
          _textFieldLabel('Role'),
          _textField(_roleController),
          const SizedBox(height: 16),
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

  Widget _buildSystemPreferencesCard() {
    return _panelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SYSTEM PREFERENCES'),
          const SizedBox(height: 6),
          Text(
            'Portal Defaults',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 760;
              if (stack) {
                return Column(
                  children: [
                    _textFieldLabel('Application Name'),
                    _textField(_appNameController),
                    const SizedBox(height: 12),
                    _textFieldLabel('Default Theme'),
                    _dropdownField(
                      value: _selectedTheme,
                      items: const ['Light / Dark Toggle', 'Light', 'Dark'],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedTheme = value);
                        _applyTheme(value);
                      },
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textFieldLabel('Application Name'),
                            _textField(_appNameController),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textFieldLabel('Default Theme'),
                            _dropdownField(
                              value: _selectedTheme,
                              items: const ['Light / Dark Toggle', 'Light', 'Dark'],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedTheme = value);
                                _applyTheme(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SizedBox.shrink(),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _solidButton('Save Preferences', onTap: () {}),
              const SizedBox(width: 10),
              _ghostButton('Reset', onTap: () {}),
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

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down, color: _mutedDark),
      dropdownColor: _surfaceDark,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _bgDark.withOpacity(0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderDark),
        ),
      ),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _textDark,
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
        // Auto-upload the image immediately after selection
        await _uploadProfileImage();
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

      if (mounted) {
        setState(() {
          _profilePictureUrl = publicUrl;
          _selectedImageBytes = null; // Clear bytes after upload
          _selectedImage = null;
        });
        // Update the provider with the new profile picture URL
        ref.read(adminProfileProvider.notifier).setProfilePictureUrl(publicUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
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
      // Update the admin profile provider
      ref.read(adminProfileProvider.notifier).updateProfile(
            adminName: _adminNameController.text,
            email: _emailController.text,
            role: _roleController.text,
            profilePictureUrl: _profilePictureUrl,
          );

      // Here you would save admin profile to Supabase if needed
      // Example: await _supabase.from('admin_profiles').update({...});
      
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
    _loadAdminEmail();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _adminNameController.text = 'Admin';
      _roleController.text = 'System Administrator';
    });
  }

  void _applyTheme(String themeName) {
    // Theme preference is saved in state (_selectedTheme)
    // The MaterialApp will read this and apply the theme
    // For now, we just update the dropdown and show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme changed to: $themeName'),
        duration: const Duration(seconds: 2),
      ),
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
