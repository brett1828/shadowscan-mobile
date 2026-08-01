import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const exposureRed = Color(0xFFE31B23);

class ExposureFinding {
  const ExposureFinding({
    required this.id,
    required this.sourceName,
    required this.sourceDomain,
    required this.breachDate,
    required this.description,
    required this.dataClasses,
    required this.severity,
  });

  final String id;
  final String sourceName;
  final String sourceDomain;
  final String breachDate;
  final String description;
  final List<String> dataClasses;
  final String severity;

  factory ExposureFinding.fromJson(Map<String, dynamic> json) {
    return ExposureFinding(
      id: json['id'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? 'Unknown breach',
      sourceDomain: json['sourceDomain'] as String? ?? '',
      breachDate: json['breachDate'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      dataClasses: (json['dataClasses'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      severity: json['severity'] as String? ?? 'low',
    );
  }
}

class ExposureApiException implements Exception {
  const ExposureApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExposureApi {
  ExposureApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _configuredBaseUrl = String.fromEnvironment(
    'SHADOWSCAN_API_URL',
    defaultValue: 'http://localhost:8080',
  );

  Uri _uri(String path) => Uri.parse('$_configuredBaseUrl$path');

  Future<String> requestVerification(String email) async {
    final response = await _client
        .post(
          _uri('/api/v1/verification/request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'consentGranted': true}),
        )
        .timeout(const Duration(seconds: 25));

    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ExposureApiException(_message(body, 'Unable to send verification code.'));
    }
    return body['requestId'] as String;
  }

  Future<({String identityId, String email})> confirmVerification({
    required String requestId,
    required String code,
  }) async {
    final response = await _client
        .post(
          _uri('/api/v1/verification/confirm'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'requestId': requestId, 'code': code}),
        )
        .timeout(const Duration(seconds: 25));

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ExposureApiException(_message(body, 'Verification failed.'));
    }
    return (
      identityId: body['identityId'] as String,
      email: body['email'] as String,
    );
  }

  Future<List<ExposureFinding>> scan(String identityId) async {
    final response = await _client
        .post(
          _uri('/api/v1/exposure/scan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'identityId': identityId}),
        )
        .timeout(const Duration(seconds: 35));

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ExposureApiException(_message(body, 'Exposure scan failed.'));
    }
    return (body['findings'] as List<dynamic>? ?? const [])
        .map((item) => ExposureFinding.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _message(Map<String, dynamic> body, String fallback) {
    final error = body['error']?.toString();
    switch (error) {
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'consent_required':
        return 'Consent is required before monitoring an email.';
      case 'email_delivery_failed':
        return 'The verification email could not be delivered.';
      case 'incorrect_code':
        return 'That verification code is incorrect.';
      case 'verification_expired':
        return 'That verification code has expired.';
      case 'too_many_attempts':
        return 'Too many attempts. Request a new code.';
      case 'provider_rate_limited':
        return 'The breach provider is temporarily rate limited.';
      case 'provider_unavailable':
        return 'The breach provider is temporarily unavailable.';
      case 'provider_not_configured':
        return 'The breach provider has not been configured yet.';
      case 'verification_unavailable':
        return 'Email verification has not been configured yet.';
      default:
        return fallback;
    }
  }
}

class ExposureCenter extends StatefulWidget {
  const ExposureCenter({super.key});

  @override
  State<ExposureCenter> createState() => _ExposureCenterState();
}

class _ExposureCenterState extends State<ExposureCenter> {
  final _api = ExposureApi();
  bool _loading = true;
  bool _scanning = false;
  String? _identityId;
  String? _email;
  String? _error;
  List<ExposureFinding> _findings = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedIdentity();
  }

  Future<void> _loadSavedIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    _identityId = prefs.getString('exposure_identity_id');
    _email = prefs.getString('exposure_email');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startVerification() async {
    final result = await Navigator.push<VerifiedIdentity>(
      context,
      MaterialPageRoute(builder: (_) => VerificationFlow(api: _api)),
    );
    if (result == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exposure_identity_id', result.identityId);
    await prefs.setString('exposure_email', result.email);
    if (!mounted) return;
    setState(() {
      _identityId = result.identityId;
      _email = result.email;
      _findings = const [];
      _error = null;
    });
    await _runScan();
  }

  Future<void> _runScan() async {
    final identityId = _identityId;
    if (identityId == null) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final findings = await _api.scan(identityId);
      if (!mounted) return;
      setState(() => _findings = findings);
    } on ExposureApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not reach the ShadowScan service. Check the API address and try again.');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _removeIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exposure_identity_id');
    await prefs.remove('exposure_email');
    if (!mounted) return;
    setState(() {
      _identityId = null;
      _email = null;
      _findings = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: exposureRed));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        const Text('Exposure', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Verify an email address and check it against known breach intelligence.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        if (_identityId == null) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mark_email_read_outlined, color: exposureRed, size: 42),
                  SizedBox(height: 14),
                  Text('Add a monitored email', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text('We verify ownership before any breach lookup. ShadowScan never asks for your email password.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _startVerification,
            icon: const Icon(Icons.add),
            label: const Text('ADD AND VERIFY EMAIL'),
          ),
        ] else ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x332ECC71),
                child: Icon(Icons.verified, color: Colors.greenAccent),
              ),
              title: const Text('Verified email', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(_email ?? ''),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') _removeIdentity();
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remove email'))],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _scanning ? null : _runScan,
            icon: _scanning
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.radar),
            label: Text(_scanning ? 'SCANNING' : 'RUN EXPOSURE SCAN'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: exposureRed),
                title: const Text('Scan unavailable'),
                subtitle: Text(_error!),
              ),
            ),
          ],
          if (!_scanning && _error == null) ...[
            const SizedBox(height: 20),
            Text(
              _findings.isEmpty ? 'No findings loaded' : '${_findings.length} known exposure${_findings.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (_findings.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: exposureRed),
                  title: Text('Run a scan'),
                  subtitle: Text('Results will appear here after the verified email is checked.'),
                ),
              )
            else
              ..._findings.map(
                (finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _severityColor(finding.severity).withValues(alpha: .18),
                        child: Icon(Icons.warning_amber, color: _severityColor(finding.severity)),
                      ),
                      title: Text(finding.sourceName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${finding.severity.toUpperCase()} • ${finding.breachDate}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExposureFindingScreen(finding: finding)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Breach intelligence provided through the configured ShadowScan data provider. No result means no known match in the current source, not a guarantee that an account was never exposed.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class VerifiedIdentity {
  const VerifiedIdentity(this.identityId, this.email);
  final String identityId;
  final String email;
}

class VerificationFlow extends StatefulWidget {
  const VerificationFlow({super.key, required this.api});
  final ExposureApi api;

  @override
  State<VerificationFlow> createState() => _VerificationFlowState();
}

class _VerificationFlowState extends State<VerificationFlow> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _requestId;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final requestId = await widget.api.requestVerification(_emailController.text.trim());
      if (mounted) setState(() => _requestId = requestId);
    } on ExposureApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the ShadowScan service.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    final requestId = _requestId;
    if (requestId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.confirmVerification(
        requestId: requestId,
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, VerifiedIdentity(result.identityId, result.email));
    } on ExposureApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the ShadowScan service.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitingForCode = _requestId != null;
    return Scaffold(
      appBar: AppBar(title: Text(waitingForCode ? 'Verify email' : 'Add email')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(waitingForCode ? Icons.mark_email_read_outlined : Icons.alternate_email, size: 58, color: exposureRed),
          const SizedBox(height: 18),
          Text(
            waitingForCode ? 'Enter the six-digit code' : 'Monitor your email exposure',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            waitingForCode
                ? 'A verification code was sent to ${_emailController.text.trim()}.'
                : 'Ownership verification is required before ShadowScan checks an email against breach intelligence.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (!waitingForCode) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              activeColor: exposureRed,
              onChanged: (value) => setState(() => _consent = value ?? false),
              title: const Text('I consent to checking this verified email against third-party breach intelligence.'),
              subtitle: const Text('ShadowScan never requests or transmits your email password.'),
            ),
          ] else
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(labelText: 'Verification code', border: OutlineInputBorder()),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: exposureRed, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : waitingForCode
                    ? _confirmCode
                    : (_consent && _emailController.text.contains('@') ? _requestCode : null),
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(waitingForCode ? 'VERIFY EMAIL' : 'SEND VERIFICATION CODE'),
          ),
        ],
      ),
    );
  }
}

class ExposureFindingScreen extends StatelessWidget {
  const ExposureFindingScreen({super.key, required this.finding});
  final ExposureFinding finding;

  List<String> get recommendedActions {
    final values = finding.dataClasses.map((value) => value.toLowerCase()).toSet();
    final actions = <String>[];
    if (values.any((value) => value.contains('password'))) {
      actions.addAll([
        'Change the affected account password.',
        'Replace any reused passwords on other accounts.',
        'Enable multi-factor authentication.',
        'Review recent sign-ins and active sessions.',
      ]);
    }
    if (values.any((value) => value.contains('phone'))) {
      actions.add('Add or confirm a carrier account PIN to reduce SIM-swap risk.');
    }
    if (values.any((value) => value.contains('address') || value.contains('birth'))) {
      actions.add('Be alert for targeted identity-verification and impersonation scams.');
    }
    if (actions.isEmpty) {
      actions.addAll([
        'Review the affected account security settings.',
        'Watch for suspicious messages related to the breached service.',
        'Use a unique password and enable MFA when available.',
      ]);
    }
    return actions.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exposure finding')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(finding.sourceName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          if (finding.sourceDomain.isNotEmpty) Text(finding.sourceDomain, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(Icons.warning_amber, color: _severityColor(finding.severity)),
              label: Text('${finding.severity.toUpperCase()} SEVERITY'),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Breach date', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(finding.breachDate),
                  const SizedBox(height: 14),
                  const Text('Exposed data', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: finding.dataClasses.map((item) => Chip(label: Text(item))).toList(),
                  ),
                ],
              ),
            ),
          ),
          if (finding.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('What happened', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_stripHtml(finding.description), style: const TextStyle(height: 1.45)),
          ],
          const SizedBox(height: 22),
          const Text('Recommended actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...recommendedActions.asMap().entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: exposureRed, child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return Colors.redAccent;
    case 'high':
      return Colors.deepOrangeAccent;
    case 'moderate':
      return Colors.amber;
    default:
      return Colors.blueAccent;
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
