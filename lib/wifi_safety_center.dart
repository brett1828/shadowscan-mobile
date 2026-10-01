import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _red = Color(0xFFE31B23);

enum _WifiAnswer { yes, no, notSure }

class WifiSafetyCenter extends StatefulWidget {
  const WifiSafetyCenter({super.key});

  @override
  State<WifiSafetyCenter> createState() => _WifiSafetyCenterState();
}

class _WifiSafetyCenterState extends State<WifiSafetyCenter> {
  _WifiAnswer? _publicNetwork;
  _WifiAnswer? _verifiedName;
  _WifiAnswer? _securedNetwork;
  _WifiAnswer? _autoJoinDisabled;
  _WifiAnswer? _sensitiveActivityProtected;
  int? _lastScore;
  bool _showHowItWorks = false;

  bool get _complete =>
      _publicNetwork != null &&
      _verifiedName != null &&
      _securedNetwork != null &&
      _autoJoinDisabled != null &&
      _sensitiveActivityProtected != null;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('wifi_safety_score');
    if (mounted) setState(() => _lastScore = score);
  }

  int _penaltyFor(
    _WifiAnswer? answer, {
    required int noPenalty,
    required int unsurePenalty,
  }) {
    if (answer == _WifiAnswer.no) return noPenalty;
    if (answer == _WifiAnswer.notSure) return unsurePenalty;
    return 0;
  }

  Future<void> _calculate() async {
    if (!_complete) return;

    final isPublic = _publicNetwork == _WifiAnswer.yes;
    final publicUnknown = _publicNetwork == _WifiAnswer.notSure;
    var score = 100;

    if (publicUnknown) score -= 5;

    score -= _penaltyFor(
      _verifiedName,
      noPenalty: isPublic ? 20 : 10,
      unsurePenalty: isPublic ? 10 : 5,
    );
    score -= _penaltyFor(
      _securedNetwork,
      noPenalty: isPublic ? 20 : 12,
      unsurePenalty: isPublic ? 10 : 6,
    );
    score -= _penaltyFor(
      _autoJoinDisabled,
      noPenalty: 15,
      unsurePenalty: 8,
    );

    if (_sensitiveActivityProtected == _WifiAnswer.no) {
      score -= isPublic ? 30 : (publicUnknown ? 20 : 10);
    } else if (_sensitiveActivityProtected == _WifiAnswer.notSure) {
      score -= isPublic ? 15 : (publicUnknown ? 10 : 5);
    }

    if (isPublic && _securedNetwork == _WifiAnswer.no) {
      score -= 5;
    }

    score = score.clamp(0, 100).toInt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wifi_safety_score', score);
    await prefs.setString('wifi_safety_checked_at', DateTime.now().toIso8601String());
    if (mounted) setState(() => _lastScore = score);
  }

  String get _rating {
    final score = _lastScore ?? 0;
    if (score >= 85) return 'Lower observed risk';
    if (score >= 65) return 'Use caution';
    return 'Higher observed risk';
  }

  void _showSettingsHelp(String title, List<String> steps) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12161C),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        const Text('Wi-Fi Safety', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Run a guided safety check before using this network for sensitive activity.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: _red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Guided network safety check',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Answer a few questions about the network and how you plan to use it. ShadowScan combines those answers into practical guidance.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showHowItWorks = !_showHowItWorks),
                  icon: Icon(_showHowItWorks ? Icons.expand_less : Icons.info_outline),
                  label: Text(_showHowItWorks ? 'HIDE DETAILS' : 'HOW THIS WORKS'),
                ),
                if (_showHowItWorks)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Mobile operating systems and browsers do not expose every Wi-Fi security property to apps. V1 therefore uses a user-assisted check instead of pretending to perform a network scan it cannot reliably complete.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_lastScore != null) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _lastScore! / 100,
                          strokeWidth: 8,
                          color: _red,
                          backgroundColor: Colors.white12,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_lastScore', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                            const Text('/ 100', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Network Safety Score', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(_rating, style: const TextStyle(color: _red, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text(
                          'A guided snapshot of this network and your planned behavior.',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text('Quick network check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _AnswerQuestion(
          title: 'Is this a public or shared network?',
          value: _publicNetwork,
          onChanged: (value) => setState(() => _publicNetwork = value),
        ),
        _AnswerQuestion(
          title: 'Did you verify the exact network name?',
          value: _verifiedName,
          onChanged: (value) => setState(() => _verifiedName = value),
        ),
        _AnswerQuestion(
          title: 'Is the network protected rather than completely open?',
          value: _securedNetwork,
          onChanged: (value) => setState(() => _securedNetwork = value),
        ),
        _AnswerQuestion(
          title: 'Is automatic connection to open networks disabled?',
          value: _autoJoinDisabled,
          onChanged: (value) => setState(() => _autoJoinDisabled = value),
        ),
        _AnswerQuestion(
          title: 'For sensitive activity, are you using cellular data or a trusted VPN when appropriate?',
          value: _sensitiveActivityProtected,
          onChanged: (value) => setState(() => _sensitiveActivityProtected = value),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _complete ? _calculate : null,
          icon: const Icon(Icons.security),
          label: const Text('CHECK THIS NETWORK'),
        ),
        const SizedBox(height: 22),
        const Text('Safer Wi-Fi habits', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const _GuidanceTile(
          Icons.cell_tower,
          'Use cellular data for high-risk tasks',
          'Banking, password changes, and account recovery are better handled on a connection you trust.',
        ),
        const _GuidanceTile(
          Icons.wifi_find,
          'Confirm the SSID',
          'Lookalike network names can be used to impersonate legitimate public Wi-Fi.',
        ),
        _GuidanceTile(
          Icons.phonelink_lock,
          'Keep auto-join restricted',
          'Prevent the device from silently reconnecting to open networks.',
          actionLabel: 'SHOW ME HOW',
          onTap: () => _showSettingsHelp(
            'Restrict automatic Wi-Fi connections',
            const [
              'On iPhone, open Settings → Wi-Fi and review Ask to Join Networks and Auto-Join Hotspot settings.',
              'For a saved network, tap the info button beside its name and turn off Auto-Join if you do not want automatic reconnection.',
              'On Android, open Wi-Fi or Network settings and review automatic connection options for saved or open networks.',
            ],
          ),
        ),
        _GuidanceTile(
          Icons.privacy_tip_outlined,
          'Use Private Wi-Fi Address when available',
          'Randomized device addressing can reduce passive tracking across networks.',
          actionLabel: 'SHOW ME HOW',
          onTap: () => _showSettingsHelp(
            'Private Wi-Fi Address',
            const [
              'On iPhone, open Settings → Wi-Fi.',
              'Tap the info button beside the connected network.',
              'Review the Private Wi-Fi Address setting and keep it enabled when appropriate.',
              'On Android, look for a Privacy or MAC address option in the saved network settings and use randomized MAC addressing when available.',
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerQuestion extends StatelessWidget {
  const _AnswerQuestion({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final _WifiAnswer? value;
  final ValueChanged<_WifiAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SegmentedButton<_WifiAnswer>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _WifiAnswer.yes, label: Text('Yes')),
                ButtonSegment(value: _WifiAnswer.no, label: Text('No')),
                ButtonSegment(value: _WifiAnswer.notSure, label: Text('Not sure')),
              ],
              selected: value == null ? <_WifiAnswer>{} : <_WifiAnswer>{value!},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceTile extends StatelessWidget {
  const _GuidanceTile(
    this.icon,
    this.title,
    this.body, {
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: _red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            if (actionLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                actionLabel!,
                style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
