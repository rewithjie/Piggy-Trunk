import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/services/email_service.dart';

class GoogleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String webClientId = '1011881228900-5h8q2u45cv9p8vurqu70e032fb8hjon7.apps.googleusercontent.com';
  static const String androidClientId = '1011881228900-de0pk92lqv378o0t06kc6227arog3kh0.apps.googleusercontent.com';

  /// Sign in with Google Auth natively or fallback smoothly
  Future<Map<String, dynamic>> signInWithGoogle({
    required String targetRole,
    bool isSignUpMode = false,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? webClientId : androidClientId,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      // Force account chooser by signing out previous local google session
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      GoogleSignInAccount? googleUser;
      String? googleErr;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        googleErr = e.toString();
        debugPrint('GoogleSignIn exception: $e');
      }

      if (googleUser == null) {
        // Try Supabase OAuth fallback if native GoogleSignIn fails or is unconfigured
        try {
          final bool oAuthStarted = await _supabase.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb ? null : 'io.supabase.piggytrunk://login-callback',
          );
          if (oAuthStarted) {
            final user = _supabase.auth.currentUser;
            if (user != null && user.email != null) {
              final String email = user.email!;
              final String fullName = user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  email.split('@').first;
              return await registerGoogleUserWithEmail(
                email: email,
                targetRole: targetRole,
                fullName: fullName,
                isSignUpMode: isSignUpMode,
              );
            }
          }
        } catch (oauthEx) {
          debugPrint('Supabase signInWithOAuth exception: $oauthEx');
        }

        return {
          'success': false,
          'message': googleErr != null
              ? 'Kanselado ang Google Sign-In.'
              : 'Hindi maikonekta ang Google Sign-In. Siguraduhing nakasetup ang Google OAuth Client ID o subukan ang email signup/login.',
        };
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken != null) {
        try {
          await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
        } catch (tokenErr) {
          debugPrint('Supabase signInWithIdToken notice: $tokenErr');
        }
      }

      final String email = googleUser.email;
      final String fullName = googleUser.displayName ?? email.split('@').first;

      return await registerGoogleUserWithEmail(
        email: email,
        targetRole: targetRole,
        fullName: fullName,
        isSignUpMode: isSignUpMode,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sa Google Login: ${e.toString()}',
      };
    }
  }

  String _toUuid(String str) {
    final String? authId = _supabase.auth.currentUser?.id;
    if (authId != null && authId.contains('-')) {
      return authId;
    }
    final rawHex = str.codeUnits.map((b) => b.toRadixString(16).padLeft(2, '0')).join().padRight(32, '0');
    final s = rawHex.substring(0, 32);
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-4${s.substring(13, 16)}-a${s.substring(17, 20)}-${s.substring(20, 32)}';
  }

  /// Register or authenticate Google User by email directly in Supabase
  Future<Map<String, dynamic>> registerGoogleUserWithEmail({
    required String email,
    required String targetRole,
    String? fullName,
    bool isSignUpMode = false,
  }) async {
    try {
      final nameToUse = (fullName != null && fullName.isNotEmpty)
          ? fullName
          : email.split('@').first;
      
      final String? authId = _supabase.auth.currentUser?.id;
      final String validGoogleUuid = (authId != null && authId.contains('-'))
          ? authId
          : _toUuid(email);

      Map<String, dynamic>? existingUser;
      try {
        existingUser = await _supabase
            .from('app_users')
            .select('user_id, status, role')
            .or('email.eq.$email,supabase_user_id.eq.$validGoogleUuid')
            .maybeSingle();
      } catch (_) {}

      String role = targetRole;
      String status = 'Pending';

      if (existingUser == null) {
        // If user clicked Google Sign-In on LOGIN screen (isSignUpMode = false) and has no account:
        if (!isSignUpMode) {
          await _supabase.auth.signOut();
          return {
            'success': false,
            'message': 'Walang nakalaang account sa Google email na ito ($email). Mangyaring mag-Sign Up muna.',
          };
        }
        dynamic newUserId;
        try {
          final insertedUser = await _supabase.from('app_users').upsert({
            'supabase_user_id': validGoogleUuid,
            'email': email,
            'name': nameToUse,
            'role': targetRole,
            'status': 'Pending',
          }, onConflict: 'email').select('user_id').single();

          newUserId = insertedUser['user_id'];
        } catch (insertErr) {
          debugPrint('app_users upsert notice: $insertErr');
          try {
            final fetchedUser = await _supabase
                .from('app_users')
                .select('user_id')
                .eq('email', email)
                .maybeSingle();
            if (fetchedUser != null) {
              newUserId = fetchedUser['user_id'];
            }
          } catch (_) {}
        }

        if (newUserId != null) {
          if (targetRole == 'hog_raiser' || targetRole == 'raiser') {
            try {
              await _supabase.from('hog_raisers').insert({
                'user_id': newUserId,
                'name': nameToUse,
                'phone': 'N/A',
                'address': 'N/A',
                'status': 'Inactive',
                'account_status': 'Pending',
                'pig_type': 'N/A',
                'lifecycle_stage': 'N/A',
              });
            } catch (raiserErr) {
              debugPrint('Hog raiser auto-create notice: $raiserErr');
            }
          } else if (targetRole == 'partner') {
            try {
              await _supabase.from('partner_investors').insert({
                'user_id': newUserId,
                'status': 'Pending',
              });
            } catch (partnerErr) {
              debugPrint('Partner investor auto-create notice: $partnerErr');
            }
          } else if (targetRole == 'cashier') {
            try {
              await _supabase.from('cashiers').insert({
                'user_id': newUserId,
                'status': 'Pending',
              });
            } catch (cashierErr) {
              debugPrint('Cashier auto-create notice: $cashierErr');
            }
          }

          // Trigger Registration Email via Resend
          try {
            EmailService().sendRegistrationEmail(
              recipientEmail: email,
              recipientName: nameToUse,
              role: targetRole,
            );
          } catch (emailErr) {
            debugPrint('Email send notice: $emailErr');
          }
        }
        role = targetRole;
        status = 'Pending';
      } else {
        final currentRole = (existingUser['role'] ?? '').toString();
        final currentStatus = (existingUser['status'] ?? 'Pending').toString();
        final existingUserId = existingUser['user_id'];

        if (currentRole.isNotEmpty &&
            currentRole.toLowerCase() != targetRole.toLowerCase() &&
            currentStatus.toLowerCase() != 'pending') {
          final displayCurrentRole = _formatRoleName(currentRole);
          final displayTargetRole = _formatRoleName(targetRole);
          return {
            'success': false,
            'message': 'Ang Google account na ito ay nakarehistro na bilang $displayCurrentRole. Hindi ito pwedeng gamitin sa $displayTargetRole registration.',
          };
        }

        // Update role and re-initialize role table if account is still pending
        if (currentStatus.toLowerCase() == 'pending') {
          try {
            await _supabase
                .from('app_users')
                .update({'role': targetRole, 'status': 'Pending'})
                .eq('user_id', existingUserId);
          } catch (_) {}

          if (targetRole == 'hog_raiser' || targetRole == 'raiser') {
            try {
              final exists = await _supabase.from('hog_raisers').select('hog_raiser_id').eq('user_id', existingUserId).maybeSingle();
              if (exists == null) {
                await _supabase.from('hog_raisers').insert({
                  'user_id': existingUserId,
                  'name': nameToUse,
                  'phone': 'N/A',
                  'address': 'N/A',
                  'status': 'Inactive',
                  'account_status': 'Pending',
                  'pig_type': 'N/A',
                  'lifecycle_stage': 'N/A',
                });
              }
            } catch (_) {}
          }

          // Trigger Registration Email via Resend
          try {
            EmailService().sendRegistrationEmail(
              recipientEmail: email,
              recipientName: nameToUse,
              role: targetRole,
            );
          } catch (_) {}
          role = targetRole;
          status = 'Pending';
        } else {
          role = currentRole.isNotEmpty ? currentRole : targetRole;
          status = currentStatus;
        }
      }

      // Only insert admin notification IF this is a brand new / pending registration
      if (status.toLowerCase() == 'pending') {
        try {
          final String roleDisplay = targetRole == 'hog_raiser' || targetRole == 'raiser'
              ? 'Hog Raiser'
              : targetRole == 'partner'
                  ? 'Partner Investor'
                  : targetRole == 'cashier'
                      ? 'Cashier'
                      : 'User';
          await _supabase
              .from('admin_notifications')
              .delete()
              .eq('metadata->>email', email)
              .eq('type', 'user_registration');
          await _supabase.from('admin_notifications').insert({
            'title': 'New User Registration',
            'message': '$nameToUse ($email) registered as $roleDisplay and is pending approval.',
            'type': 'user_registration',
            'is_read': false,
            'metadata': {
              'name': nameToUse,
              'email': email,
              'role': targetRole,
            },
          });
        } catch (_) {}
      } else if (status.toLowerCase() == 'active') {
        // If user is already approved and active, remove any leftover pending registration notifications
        try {
          await _supabase
              .from('admin_notifications')
              .delete()
              .eq('metadata->>email', email)
              .eq('type', 'user_registration');
        } catch (_) {}
      }

      return {
        'success': true,
        'email': email,
        'role': role,
        'status': status,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sa Google Registration: ${e.toString()}',
      };
    }
  }

  String _formatRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'hog_raiser':
        return 'Hog Raiser';
      case 'partner':
        return 'Partner Investor';
      case 'cashier':
        return 'Cashier';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }
}
