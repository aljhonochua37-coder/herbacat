import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' as mailer_smtp;

String? _getEnv(String key) {
  if (kIsWeb) return null;
  try {
    return Platform.environment[key];
  } catch (_) {
    return null;
  }
}

class SentEmailRecord {
  final String recipient;
  final String subject;
  final String token;
  final String verificationUrl;
  final String htmlBody;
  final String textBody;
  final DateTime sentAt;
  final bool deliveredViaSmtp;

  SentEmailRecord({
    required this.recipient,
    required this.subject,
    required this.token,
    required this.verificationUrl,
    required this.htmlBody,
    required this.textBody,
    required this.sentAt,
    required this.deliveredViaSmtp,
  });

  Map<String, dynamic> toJson() => {
        'recipient': recipient,
        'subject': subject,
        'token': token,
        'verificationUrl': verificationUrl,
        'sentAt': sentAt.toIso8601String(),
        'deliveredViaSmtp': deliveredViaSmtp,
      };
}

class EmailSendResult {
  final bool success;
  final bool isLiveSmtp;
  final String message;
  final String? token;
  final String? link;

  const EmailSendResult({
    required this.success,
    required this.isLiveSmtp,
    required this.message,
    this.token,
    this.link,
  });
}

class EmailService {
  final String? smtpHost;
  final int smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final String fromAddress;
  final String appBaseUrl;

  final List<SentEmailRecord> _outbox = [];
  List<SentEmailRecord> get outbox => List.unmodifiable(_outbox);

  EmailService({
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? fromAddress,
    String? appBaseUrl,
  })  : smtpHost = smtpHost ?? _getEnv('HERBACAT_SMTP_HOST'),
        smtpPort = smtpPort ??
            int.tryParse(_getEnv('HERBACAT_SMTP_PORT') ?? '587') ??
            587,
        smtpUsername = smtpUsername ?? _getEnv('HERBACAT_SMTP_USER'),
        smtpPassword = smtpPassword ?? _getEnv('HERBACAT_SMTP_PASS'),
        fromAddress = fromAddress ??
            _getEnv('HERBACAT_SMTP_FROM') ??
            'HerbaCat Field Registry <no-reply@herbacat.gov.ph>',
        appBaseUrl = appBaseUrl ??
            _getEnv('HERBACAT_APP_URL') ??
            'https://herbacat.app';

  bool get hasSmtpConfigured =>
      smtpHost != null &&
      smtpHost!.isNotEmpty &&
      smtpUsername != null &&
      smtpUsername!.isNotEmpty &&
      smtpPassword != null &&
      smtpPassword!.isNotEmpty;

  /// Sends account verification email
  Future<EmailSendResult> sendVerificationEmail({
    required String email,
    required String name,
    required String token,
  }) async {
    final verifyUrl = '$appBaseUrl/verify?token=$token&email=${Uri.encodeComponent(email)}';
    final subject = 'Verify your HerbaCat Botanical Registry Account';

    final textBody = '''
Mabuhay $name,

Welcome to HerbaCat - Catanduanes Ethnobotanical Field Guide.
Please verify your email address to unlock full field journal and bookmarking features.

Verification Link:
$verifyUrl

Single-Use Verification Code:
$token

This verification link expires in 24 hours.

If you did not register for this account, you can safely ignore this email.

Warm regards,
HerbaCat Botanical Preservation Team
Virac, Catanduanes
''';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #FCF9F2; color: #1C1C18; margin: 0; padding: 24px; }
    .card { max-width: 540px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; padding: 32px; border: 1px solid #E5E2DB; box-shadow: 0 4px 16px rgba(68,43,33,0.06); }
    .header { color: #94452C; font-size: 22px; font-weight: bold; margin-bottom: 8px; }
    .badge { display: inline-block; background: #BEEAD1; color: #436B58; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: 600; margin-bottom: 16px; }
    .btn { display: inline-block; background: #006A46; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 9999px; font-weight: 600; margin: 20px 0; }
    .code-box { background: #F1EEE7; border-radius: 12px; padding: 12px; font-family: monospace; font-size: 16px; letter-spacing: 2px; text-align: center; margin: 12px 0; }
    .footer { font-size: 12px; color: #88726C; margin-top: 24px; border-top: 1px solid #E5E2DB; pt: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">Catanduanes Ethnobotanical Archive</div>
    <div class="header">Verify Your HerbaCat Account</div>
    <p>Mabuhay <strong>$name</strong>,</p>
    <p>Thank you for registering with HerbaCat. To verify your email and activate your personal field journal, please click the button below:</p>
    <div style="text-align: center;">
      <a class="btn" href="$verifyUrl">Verify My Account</a>
    </div>
    <p>Or enter this verification token directly in the app:</p>
    <div class="code-box">$token</div>
    <p style="font-size: 13px; color: #55433E;">This link will expire in 24 hours.</p>
    <div class="footer">
      HerbaCat Project • Virac, Catanduanes • Pacific Biosphere<br/>
      If you did not request this, please disregard this email.
    </div>
  </div>
</body>
</html>
''';

    return _dispatchEmail(
      recipient: email,
      subject: subject,
      textBody: textBody,
      htmlBody: htmlBody,
      token: token,
      link: verifyUrl,
    );
  }

  /// Sends password reset email
  Future<EmailSendResult> sendPasswordResetEmail({
    required String email,
    required String name,
    required String token,
  }) async {
    final resetUrl = '$appBaseUrl/reset-password?token=$token&email=${Uri.encodeComponent(email)}';
    final subject = 'Reset your HerbaCat Account Password';

    final textBody = '''
Mabuhay $name,

We received a request to reset the password for your HerbaCat field explorer account.

Password Reset Link:
$resetUrl

Single-Use Reset Token:
$token

This password reset link expires in 1 hour.

If you did not request a password reset, no action is needed. Your account remains secure.

Warm regards,
HerbaCat Security Team
Virac, Catanduanes
''';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #FCF9F2; color: #1C1C18; margin: 0; padding: 24px; }
    .card { max-width: 540px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; padding: 32px; border: 1px solid #E5E2DB; box-shadow: 0 4px 16px rgba(68,43,33,0.06); }
    .header { color: #94452C; font-size: 22px; font-weight: bold; margin-bottom: 8px; }
    .btn { display: inline-block; background: #94452C; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 9999px; font-weight: 600; margin: 20px 0; }
    .code-box { background: #F1EEE7; border-radius: 12px; padding: 12px; font-family: monospace; font-size: 16px; letter-spacing: 2px; text-align: center; margin: 12px 0; }
    .footer { font-size: 12px; color: #88726C; margin-top: 24px; border-top: 1px solid #E5E2DB; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">Password Reset Request</div>
    <p>Mabuhay <strong>$name</strong>,</p>
    <p>We received a request to reset your password. Click the button below to choose a new password:</p>
    <div style="text-align: center;">
      <a class="btn" href="$resetUrl">Reset Password</a>
    </div>
    <p>Or enter this reset token directly in the HerbaCat app:</p>
    <div class="code-box">$token</div>
    <p style="font-size: 13px; color: #55433E;">This security token expires in 1 hour.</p>
    <div class="footer">
      HerbaCat Security Team • Virac, Catanduanes<br/>
      If you did not request this password reset, please ignore this email.
    </div>
  </div>
</body>
</html>
''';

    return _dispatchEmail(
      recipient: email,
      subject: subject,
      textBody: textBody,
      htmlBody: htmlBody,
      token: token,
      link: resetUrl,
    );
  }

  Future<EmailSendResult> _dispatchEmail({
    required String recipient,
    required String subject,
    required String textBody,
    required String htmlBody,
    required String token,
    required String link,
  }) async {
    bool deliveredViaSmtp = false;
    String statusMessage = '';

    if (hasSmtpConfigured) {
      try {
        final smtpServer = mailer_smtp.SmtpServer(
          smtpHost!,
          port: smtpPort,
          username: smtpUsername,
          password: smtpPassword,
          ssl: smtpPort == 465,
          allowInsecure: false,
        );

        final message = mailer.Message()
          ..from = mailer.Address(fromAddress, 'HerbaCat')
          ..recipients.add(recipient)
          ..subject = subject
          ..text = textBody
          ..html = htmlBody;

        await mailer.send(message, smtpServer);
        deliveredViaSmtp = true;
        statusMessage = 'Email dispatched successfully to $recipient via SMTP.';
      } catch (e) {
        // Fall back to outbox logging if SMTP network delivery fails
        statusMessage = 'SMTP delivery failed ($e), recorded to local outbox.';
      }
    } else {
      statusMessage = 'Email dispatched to local outbox (SMTP not configured).';
    }

    final record = SentEmailRecord(
      recipient: recipient,
      subject: subject,
      token: token,
      verificationUrl: link,
      htmlBody: htmlBody,
      textBody: textBody,
      sentAt: DateTime.now(),
      deliveredViaSmtp: deliveredViaSmtp,
    );

    _outbox.insert(0, record);
    _writeToDiskOutbox(record);

    return EmailSendResult(
      success: true,
      isLiveSmtp: deliveredViaSmtp,
      message: statusMessage,
      token: token,
      link: link,
    );
  }

  void _writeToDiskOutbox(SentEmailRecord record) {
    try {
      final dir = Directory('data/outbox');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final filename = '${dir.path}/email_${DateTime.now().millisecondsSinceEpoch}_${record.recipient.replaceAll('@', '_at_')}.txt';
      final file = File(filename);
      file.writeAsStringSync('''
TO: ${record.recipient}
SUBJECT: ${record.subject}
SENT_AT: ${record.sentAt.toIso8601String()}
DELIVERED_VIA_SMTP: ${record.deliveredViaSmtp}
TOKEN: ${record.token}
LINK: ${record.verificationUrl}
------------------------------------
${record.textBody}
''');
    } catch (_) {
      // Ignore disk writing failure if running in restricted environments
    }
  }

  /// Clears sent emails (used in unit testing)
  void clearOutbox() {
    _outbox.clear();
  }
}
