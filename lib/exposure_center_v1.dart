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
    required this.provider,
  });

  final String id;
  final String sourceName;
  final String sourceDomain;
  final String breachDate;
  final String description;
  final List<String> dataClasses;
  final String severity;
  final String provider;

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
      provider: json['provider'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceName': sourceName,
        'sourceDomain': sourceDomain,
        'breachDate': breachDate,
        'description': description,
        'dataClasses': dataClasses,
        'severity': severity,
        'provider': provider,
      };
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

  static const baseUrl = String.fromEnvironment(
    'SHADOWSCAN_API_URL',
    defaultValue: 'https://mobile.quantumshadowblackops.com',
  );

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

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

  Future<VerifiedIdentity> confirmVerification({
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

    return VerifiedIdentity(
      body['identityId'] as String,
      body['email'] as String,
    );
  }

  Future<void> deleteIdentity(String identityId) async {
    final response = await _client
        .delete(_uri('/api/v1/identities/$identityId'))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 204 && response.statusCode != 404) {
      final body = _decode(response);
      throw ExposureApiException(_message(body, 'Unable to remove the monitored email.'));
    }
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
    switch (body['error']?.toString()) {
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'consent_required':
        return 'Consent is required before monitoring an email.';
      case 'email_delivery_failed':
        return 'The verification email could not be delivered.';
      case 'incorrect_code':
        return 'That verification code is incorrect.';
      case 'verification_expired':
        return 'That verification code has expired. Request a new code.';
      case 'verification_not_found':
        return 'That verification request is no longer available.';
      case 'verification_already_used':
        return 'That verification code has already been used.';
      case 'too_many_attempts':
        return 'Too many attempts. Request a new verification code.';
      case 'verified_identity_required':
        return 'Verify this email again before scanning.';
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
  DateTime? _lastScan;
  List<ExposureFinding> _findings = const [];
  Set<String> _resolved = <String>{};

  bool get _hasScanned => _lastScan != null;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _identityId = prefs.getString('exposure_identity_id');
    _email = prefs.getString('exposure_email');

    final lastScanValue = prefs.getString('exposure_last_scan_at');
    if (lastScanValue != null) {
      _lastScan = DateTime.tryParse(lastScanValue);
    }

    final cached = prefs.getString('exposure_cached_findings');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        _findings = decoded
            .map((item) => ExposureFinding.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _findings = const [];
      }
    }

    _resolved = prefs
        .getKeys()
        .where((key) => key.startsWith('exposure_resolved_') && prefs.getBool(key) == true)
        .map((key) => key.substring('exposure_resolved_'.length))
        .toSet();

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
    await prefs.remove('exposure_cached_findings');
    await prefs.remove('exposure_last_scan_at');

    if (!mounted) return;
    setState(() {
      _identityId = result.identityId;
      _email = result.email;
      _findings = const [];
      _lastScan = null;
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
      final scannedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'exposure_cached_findings',
        jsonEncode(findings.map((finding) => finding.toJson()).toList()),
      );
      await prefs.setString('exposure_last_scan_at', scannedAt.toIso8601String());

      if (!mounted) return;
      setState(() {
        _findings = findings;
        _lastScan = scannedAt;
      });
    } on ExposureApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _hasScanned
              ? 'Live refresh failed. Showing your last saved results.'
              : 'Could not reach the ShadowScan service. Check the API connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _reloadResolutionState() async {
    final prefs = await SharedPreferences.getInstance();
    final resolved = prefs
        .getKeys()
        .where((key) => key.startsWith('exposure_resolved_') && prefs.getBool(key) == true)
        .map((key) => key.substring('exposure_resolved_'.length))
        .toSet();
    if (mounted) setState(() => _resolved = resolved);
  }

  Future<void> _openFinding(ExposureFinding finding) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExposureFindingScreen(finding: finding)),
    );
    await _reloadResolutionState();
  }

  Future<void> _removeIdentity() async {
    final identityId = _identityId;
    if (identityId != null) {
      try {
        await _api.deleteIdentity(identityId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'The email could not be removed from the server. Try again when the service is available.';
          });
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) =>
              key == 'exposure_identity_id' ||
              key == 'exposure_email' ||
              key == 'exposure_cached_findings' ||
              key == 'exposure_last_scan_at' ||
              key.startsWith('exposure_action_') ||
              key.startsWith('exposure_resolved_'),
        );
    for (final key in keys) {
      await prefs.remove(key);
    }

    if (!mounted) return;
    setState(() {
      _identityId = null;
      _email = null;
      _findings = const [];
      _resolved = <String>{};
      _lastScan = null;
      _error = null;
    });
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0 ? 12 : local.hour > 12 ? local.hour - 12 : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: exposureRed));
    }

    final unresolved = _findings.where((finding) => !_resolved.contains(finding.id)).length;

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
                  Text(
                    'We verify ownership before any breach lookup. ShadowScan never asks for your email password.',
                  ),
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
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remove', child: Text('Remove email')),
                ],
              ),
            ),
          ),
          if (_hasScanned) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Known findings',
                    value: '${_findings.length}',
                    icon: Icons.public,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Action needed',
                    value: '$unresolved',
                    icon: Icons.warning_amber,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _scanning ? null : _runScan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar),
            label: Text(_scanning ? 'SCANNING' : (_hasScanned ? 'REFRESH EXPOSURE SCAN' : 'RUN EXPOSURE SCAN')),
          ),
          if (_lastScan != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last updated ${_formatDateTime(_lastScan!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: exposureRed),
                title: const Text('Live scan unavailable'),
                subtitle: Text(_error!),
              ),
            ),
          ],
          if (!_scanning && _hasScanned) ...[
            const SizedBox(height: 20),
            Text(
              _findings.isEmpty
                  ? 'No known exposures found'
                  : '${_findings.length} known exposure${_findings.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (_findings.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.verified_user_outlined, color: Colors.greenAccent),
                  title: Text('No current matches'),
                  subtitle: Text(
                    'No known matches were returned by the current breach intelligence source.',
                  ),
                ),
              )
            else
              ..._findings.map(
                (finding) {
                  final resolved = _resolved.contains(finding.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (resolved ? Colors.greenAccent : _severityColor(finding.severity))
                              .withValues(alpha: .18),
                          child: Icon(
                            resolved ? Icons.check : Icons.warning_amber,
                            color: resolved ? Colors.greenAccent : _severityColor(finding.severity),
                          ),
                        ),
                        title: Text(finding.sourceName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          resolved
                              ? 'REMEDIATION REVIEWED • ${finding.breachDate}'
                              : '${finding.severity.toUpperCase()} • ${finding.breachDate}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openFinding(finding),
                      ),
                    ),
                  );
                },
              ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Breach intelligence for V1 is sourced through Have I Been Pwned. A clean result means no known match was returned by the current source; it is not a guarantee that the account has never been exposed.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: exposureRed),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
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
  bool _emailValid = false;
  bool _codeReady = false;
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
      if (mounted) {
        setState(() {
          _requestId = requestId;
          _codeController.clear();
          _codeReady = false;
        });
      }
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
      Navigator.pop(context, result);
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
          Icon(
            waitingForCode ? Icons.mark_email_read_outlined : Icons.alternate_email,
            size: 58,
            color: exposureRed,
          ),
          const SizedBox(height: 18),
          Text(
            waitingForCode ? 'Enter the six-digit code' : 'Monitor your email exposure',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            waitingForCode
                ? 'A verification code was sent to ${_emailController.text.trim()}. It expires after 10 minutes.'
                : 'Ownership verification is required before ShadowScan checks an email against breach intelligence.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (!waitingForCode) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onChanged: (value) {
                final trimmed = value.trim();
                setState(() {
                  _emailValid = trimmed.contains('@') && trimmed.contains('.') && trimmed.length <= 254;
                });
              },
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
              title: const Text(
                'I consent to checking this verified email against third-party breach intelligence.',
              ),
              subtitle: const Text('ShadowScan never requests or transmits your email password.'),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              textAlign: TextAlign.center,
              onChanged: (value) => setState(() {
                _codeReady = value.trim().length == 6 && int.tryParse(value.trim()) != null;
              }),
              style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _requestCode,
              child: const Text('SEND A NEW CODE'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: exposureRed, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : waitingForCode
                    ? (_codeReady ? _confirmCode : null)
                    : (_consent && _emailValid ? _requestCode : null),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(waitingForCode ? 'VERIFY EMAIL' : 'SEND VERIFICATION CODE'),
          ),
        ],
      ),
    );
  }
}

class ExposureFindingScreen extends StatefulWidget {
  const ExposureFindingScreen({super.key, required this.finding});
  final ExposureFinding finding;

  @override
  State<ExposureFindingScreen> createState() => _ExposureFindingScreenState();
}

class _ExposureFindingScreenState extends State<ExposureFindingScreen> {
  List<bool> _completed = const [];
  bool _loading = true;

  List<String> get _actions {
    final values = widget.finding.dataClasses.map((value) => value.toLowerCase()).toSet();
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

  bool get _resolved => _completed.isNotEmpty && _completed.every((value) => value);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = _actions;
    final completed = List<bool>.generate(
      actions.length,
      (index) => prefs.getBool('exposure_action_${widget.finding.id}_$index') ?? false,
    );
    if (mounted) {
      setState(() {
        _completed = completed;
        _loading = false;
      });
    }
  }

  Future<void> _setAction(int index, bool value) async {
    final next = [..._completed];
    next[index] = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exposure_action_${widget.finding.id}_$index', value);
    final resolved = next.every((item) => item);
    await prefs.setBool('exposure_resolved_${widget.finding.id}', resolved);

    if (mounted) setState(() => _completed = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: exposureRed)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Exposure finding')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.finding.sourceName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          if (widget.finding.sourceDomain.isNotEmpty)
            Text(widget.finding.sourceDomain, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  _resolved ? Icons.check_circle : Icons.warning_amber,
                  color: _resolved ? Colors.greenAccent : _severityColor(widget.finding.severity),
                ),
                label: Text(_resolved ? 'REMEDIATION REVIEWED' : '${widget.finding.severity.toUpperCase()} SEVERITY'),
              ),
              const Chip(label: Text('HIBP SOURCE')),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Breach date', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(widget.finding.breachDate),
                  const SizedBox(height: 14),
                  const Text('Exposed data', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.finding.dataClasses.map((item) => Chip(label: Text(item))).toList(),
                  ),
                ],
              ),
            ),
          ),
          if (widget.finding.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('What happened', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_stripHtml(widget.finding.description), style: const TextStyle(height: 1.45)),
          ],
          const SizedBox(height: 22),
          const Text('Recommended actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Check off each action after you have reviewed or completed it.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ..._actions.asMap().entries.map(
                (entry) => Card(
                  child: CheckboxListTile(
                    value: _completed[entry.key],
                    activeColor: exposureRed,
                    title: Text(entry.value),
                    onChanged: (value) => _setAction(entry.key, value ?? false),
                  ),
                ),
              ),
          if (_resolved) ...[
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.greenAccent),
                title: Text('Remediation reviewed'),
                subtitle: Text(
                  'This does not erase the historical breach. It records that you reviewed the recommended response steps.',
                ),
              ),
            ),
          ],
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
