import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Gets Resend API Key from .env or fallback config
  String get _apiKey {
    return dotenv.env['RESEND_API_KEY']?.trim() ?? '';
  }

  /// Base sender email for Resend (onboarding@resend.dev works out-of-the-box)
  String get _fromEmail {
    return dotenv.env['RESEND_FROM_EMAIL']?.trim() ?? 'PiggyTrunk <onboarding@resend.dev>';
  }

  /// Sends a Welcome / Registration Email when a user signs up
  Future<bool> sendRegistrationEmail({
    required String recipientEmail,
    required String recipientName,
    required String role,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint("Notice: RESEND_API_KEY is not set. Skipping registration email.");
      return false;
    }

    final roleDisplay = role.toLowerCase().contains('raiser')
        ? 'Hog Raiser'
        : (role.toLowerCase().contains('partner') ? 'Partner Investor' : 'Cashier');

    final htmlContent = '''
    <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background-color: #ffffff;">
      <div style="background-color: #18314F; padding: 24px; text-align: center; color: white;">
        <h1 style="margin: 0; font-size: 24px;">PiggyTrunk 🐷</h1>
        <p style="margin: 6px 0 0 0; font-size: 14px; opacity: 0.9;">Maligayang Pagdating sa PiggyTrunk System</p>
      </div>
      <div style="padding: 24px; color: #334155; line-height: 1.6;">
        <h2 style="color: #18314F; margin-top: 0;">Kumusta, $recipientName!</h2>
        <p>Salamat sa pagre-rehistro sa <strong>PiggyTrunk</strong> bilang <strong>$roleDisplay</strong>.</p>
        <div style="background-color: #f8fafc; border-left: 4px solid #FFA566; padding: 14px; margin: 18px 0; border-radius: 4px;">
          <strong style="color: #18314F;">Status ng Account:</strong> <span style="color: #d97706; font-weight: bold;">Pending Admin Approval</span>
          <p style="margin: 4px 0 0 0; font-size: 13px; color: #64748b;">Ang iyong account ay kasalukuyang sumasailalim sa pagsusuri ng Admin bago mo ma-access ang iyong dashboard.</p>
        </div>
        <p>Makakatanggap ka ng kasunod na email kapag naprubahan na ng Admin ang iyong account.</p>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="font-size: 12px; color: #94a3b8; text-align: center;">Ito ay awtomatikong email mula sa PiggyTrunk System.</p>
      </div>
    </div>
    ''';

    return await _postEmail(
      to: recipientEmail,
      subject: 'Maligayang Pagdating sa PiggyTrunk! (Pending Approval)',
      html: htmlContent,
    );
  }

  /// Sends an Approval Email when an Admin approves the user's account
  Future<bool> sendAccountApprovalEmail({
    required String recipientEmail,
    required String recipientName,
    required String role,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint("Notice: RESEND_API_KEY is not set. Skipping approval email.");
      return false;
    }

    final roleDisplay = role.toLowerCase().contains('raiser')
        ? 'Hog Raiser'
        : (role.toLowerCase().contains('partner') ? 'Partner Investor' : 'Cashier');

    final htmlContent = '''
    <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background-color: #ffffff;">
      <div style="background-color: #18314F; padding: 24px; text-align: center; color: white;">
        <h1 style="margin: 0; font-size: 24px;">PiggyTrunk 🐷</h1>
        <p style="margin: 6px 0 0 0; font-size: 14px; opacity: 0.9;">Account Approval Notification</p>
      </div>
      <div style="padding: 24px; color: #334155; line-height: 1.6;">
        <h2 style="color: #10B981; margin-top: 0;">🎉 Aprubado na ang Iyong Account!</h2>
        <p>Magandang araw, <strong>$recipientName</strong>!</p>
        <p>Ikinagagalak naming ipaalam sa iyo na ang iyong PiggyTrunk account bilang <strong>$roleDisplay</strong> ay <strong>MATAGUMPAY NANG NA-APPROVE</strong> ng Admin.</p>
        <div style="background-color: #f0fdf4; border-left: 4px solid #10B981; padding: 14px; margin: 18px 0; border-radius: 4px;">
          <strong style="color: #15803d;">Maaari ka nang mag-log in sa app!</strong>
          <p style="margin: 4px 0 0 0; font-size: 13px; color: #166534;">Buksan ang PiggyTrunk app at mag-login gamit ang iyong email ($recipientEmail).</p>
        </div>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="font-size: 12px; color: #94a3b8; text-align: center;">Maraming salamat,<br/><strong>PiggyTrunk Team</strong></p>
      </div>
    </div>
    ''';

    return await _postEmail(
      to: recipientEmail,
      subject: '🎉 Aprubado na ang Iyong PiggyTrunk Account!',
      html: htmlContent,
    );
  }

  /// Internal HTTP POST call to Resend API endpoint
  Future<bool> _postEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.api-resend.com/emails').replace(host: 'api.resend.com'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [to],
          'subject': subject,
          'html': html,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Resend Email successfully sent to: $to");
        return true;
      } else {
        debugPrint("Resend Email failed [${response.statusCode}]: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error sending Resend email: $e");
      return false;
    }
  }
}
