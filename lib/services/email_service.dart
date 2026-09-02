import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Gets Gmail SMTP credentials from .env or fallback
  String get _gmailUser {
    return dotenv.env['GMAIL_USER']?.trim() ?? 'piggytrunk@gmail.com';
  }

  String get _gmailAppPassword {
    return dotenv.env['GMAIL_APP_PASSWORD']?.trim() ?? 'nuicsizzrnmhnuva';
  }

  /// Sends a Welcome / Registration Email when a user signs up
  Future<bool> sendRegistrationEmail({
    required String recipientEmail,
    required String recipientName,
    required String role,
  }) async {
    final roleDisplay = role.toLowerCase().contains('raiser')
        ? 'Hog Raiser'
        : (role.toLowerCase().contains('partner') ? 'Partner Investor' : 'Cashier');

    final htmlContent = '''
    <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff; box-shadow: 0 6px 24px rgba(24, 49, 79, 0.08);">
      <!-- Clean Corporate Header -->
      <div style="background: linear-gradient(135deg, #18314F 0%, #0F1C2F 100%); padding: 32px 24px; text-align: center; color: white;">
        <h1 style="margin: 0; font-size: 26px; font-weight: 800; letter-spacing: 0.5px; color: #ffffff; text-transform: uppercase;">PIGGY TRUNK</h1>
      </div>

      <!-- Main Body Content -->
      <div style="padding: 30px 28px; color: #334155; line-height: 1.65;">
        <h2 style="color: #18314F; margin-top: 0; font-size: 20px; font-weight: 700;">Hello, $recipientName!</h2>
        <p style="font-size: 15px; margin: 8px 0 16px 0;">Thank you for registering on <strong>Piggy Trunk</strong> as a <strong>$roleDisplay</strong>.</p>
        
        <!-- Status Box -->
        <div style="background-color: #F8FAFC; border-left: 4px solid #FFA566; padding: 16px 18px; margin: 20px 0; border-radius: 8px; border: 1px solid #E2E8F0; border-left-width: 4px; border-left-color: #FFA566;">
          <strong style="color: #18314F; font-size: 14.5px;">Account Status:</strong> <span style="color: #D97706; font-weight: 700; font-size: 14.5px;">Pending Admin Approval</span>
          <p style="margin: 6px 0 0 0; font-size: 13.5px; color: #64748B;">Your account registration is currently under review by our administrators before you can access the dashboard.</p>
        </div>

        <p style="font-size: 14.5px; color: #475569;">You will receive another confirmation email as soon as your account has been approved by the Admin.</p>
        
        <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 26px 0;" />
        <p style="font-size: 12px; color: #94A3B8; text-align: center; margin: 0;">This is an automated notification from Piggy Trunk Support. Please do not reply directly to this email.</p>
      </div>
    </div>
    ''';

    return await _postEmail(
      to: recipientEmail,
      subject: 'Welcome to Piggy Trunk (Registration Pending Approval)',
      html: htmlContent,
    );
  }

  /// Sends an Official Approval Notification Email when Admin approves a user
  Future<bool> sendAccountApprovalEmail({
    required String recipientEmail,
    required String recipientName,
    required String role,
  }) async {
    final roleDisplay = role.toLowerCase().contains('raiser')
        ? 'Hog Raiser'
        : (role.toLowerCase().contains('partner') ? 'Partner Investor' : 'Cashier');

    final htmlContent = '''
    <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff; box-shadow: 0 6px 24px rgba(24, 49, 79, 0.08);">
      <!-- Clean Corporate Header -->
      <div style="background: linear-gradient(135deg, #18314F 0%, #0F1C2F 100%); padding: 32px 24px; text-align: center; color: white;">
        <h1 style="margin: 0; font-size: 26px; font-weight: 800; letter-spacing: 0.5px; color: #ffffff; text-transform: uppercase;">PIGGY TRUNK</h1>
      </div>

      <!-- Main Body Content -->
      <div style="padding: 30px 28px; color: #334155; line-height: 1.65;">
        <h2 style="color: #10B981; margin-top: 0; font-size: 21px; font-weight: 800;">Account Approved</h2>
        <p style="font-size: 15px; margin: 8px 0 16px 0;">Good day, <strong>$recipientName</strong>!</p>
        <p style="font-size: 15px; margin-bottom: 18px;">We are pleased to inform you that your Piggy Trunk account as a <strong>$roleDisplay</strong> has been <strong>OFFICIALLY APPROVED</strong> by the Admin.</p>
        
        <!-- Success Action Box -->
        <div style="background-color: #F0FDF4; border-left: 4px solid #10B981; padding: 18px 20px; margin: 20px 0; border-radius: 8px; border: 1px solid #BBF7D0; border-left-width: 4px; border-left-color: #10B981;">
          <strong style="color: #15803D; font-size: 15px;">You can now sign in to your mobile app!</strong>
          <p style="margin: 6px 0 0 0; font-size: 13.5px; color: #166534;">Open the Piggy Trunk app and log in using your registered email address ($recipientEmail).</p>
        </div>

        <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 26px 0;" />
        <p style="font-size: 13.5px; color: #64748B; margin: 0;">Best regards,<br/><strong style="color: #18314F; font-size: 14.5px;">Piggy Trunk Support</strong></p>
      </div>
    </div>
    ''';

    return await _postEmail(
      to: recipientEmail,
      subject: '🎉 Your Piggy Trunk Account is Approved!',
      html: htmlContent,
    );
  }

  /// Sends email using Gmail SMTP mailer on native mobile / desktop platforms, or Vercel / Supabase on Web
  Future<bool> _postEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    // 1. Direct Gmail SMTP via Mailer (Native on Android, iOS, Windows, Mac)
    if (!kIsWeb) {
      try {
        final smtpServer = gmail(_gmailUser, _gmailAppPassword);

        final message = Message()
          ..from = Address(_gmailUser, 'Piggy Trunk Support')
          ..recipients.add(to)
          ..subject = subject
          ..html = html;

        final sendReport = await send(message, smtpServer);
        debugPrint('Gmail SMTP Email successfully sent to $to: ${sendReport.toString()}');
        return true;
      } catch (e) {
        debugPrint('Gmail SMTP native warning: $e. Trying cloud fallback...');
      }
    }

    // 2. Web Bridge (Local dev bridge on localhost:3001 or Vercel serverless on production)
    if (kIsWeb) {
      // 2a. Try local dev bridge if running locally
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3001'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': to,
            'subject': subject,
            'html': html,
          }),
        );
        if (response.statusCode == 200) {
          debugPrint('Local SMTP Bridge Email delivered to: $to');
          return true;
        }
      } catch (_) {
        // Not running local bridge, continue to Vercel endpoint
      }

      // 2b. Try Vercel Serverless Function (When hosted on Vercel)
      try {
        final response = await http.post(
          Uri.parse('/api/send-email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': to,
            'subject': subject,
            'html': html,
          }),
        );
        if (response.statusCode == 200) {
          debugPrint('Vercel Serverless Email delivered to: $to');
          return true;
        }
      } catch (vercelErr) {
        debugPrint('Vercel API notice: $vercelErr');
      }
    }

    // 3. Supabase Edge Function (Works on Web and Cloud environments)
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'html': html,
        },
      );
      if (response.status == 200) {
        debugPrint('Supabase Edge Function Email sent successfully to $to');
        return true;
      }
    } catch (edgeErr) {
      debugPrint('Supabase Edge Function notice: $edgeErr');
    }

    // 4. HTTP Fallback (for Web / Cloud endpoints)
    try {
      final resendKey = dotenv.env['RESEND_API_KEY']?.trim() ?? '';
      if (resendKey.isNotEmpty) {
        final response = await http.post(
          Uri.parse('https://api.resend.com/emails'),
          headers: {
            'Authorization': 'Bearer $resendKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'from': 'Piggy Trunk Support <onboarding@resend.dev>',
            'to': [to],
            'subject': subject,
            'html': html,
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('HTTP Email sent successfully to: $to');
          return true;
        }
      }
    } catch (_) {}

    return false;
  }
}

