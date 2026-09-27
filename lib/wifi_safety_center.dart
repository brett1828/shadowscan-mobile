import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _red = Color(0xFFE31B23);

class WifiSafetyCenter extends StatefulWidget {
  const WifiSafetyCenter({super.key});

  @override
  State<WifiSafetyCenter> createState() => _WifiSafetyCenterState();
}

class _WifiSafetyCenterState extends State<WifiSafetyCenter> {
  bool? _publicNetwork;
  bool? _verifiedName;
  bool? _securedNetwork;
  bool? _autoJoinDisabled;
  bool? _sensitiveActivityProtected;
  int? _lastScore;

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

  Future<void> _calculate() async {
    if (!_complete) return;
    var score = 100;
    if (_publicNetwork == true) score -= 20;
    if (_verifiedName == false) score -= 25;
    if (_securedNetwork == false) score -= 25;
    if (_autoJoinDisabled == false) score -= 15;
    if (_sensitiveActivityProtected == false) score -= 15;
    score = score.clamp(0, 100);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wifi_safety_score', score);
    await prefs.setString('wifi_safety_checked_at', DateTime.now().toIso8601String());
    if (mounted) setState(() => _lastScore = score);
  }

  String get _rating {
    final score = _lastScore ?? 0;
    if (score >= 85) return 'Low observed risk';
    if (score >= 65) return 'Use caution';
    return 'Higher observed risk';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        const Text('Wi-Fi Safety', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Review the network you are using before sensitive activity.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'On iPhone and in a browser, ShadowScan cannot reliably inspect every Wi-Fi security property. This V1 check combines what you know about the network with practical security guidance.',
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
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _lastScore! / 100,
                          strokeWidth: 8,
                          color: _red,
                          backgroundColor: Colors.white12,
                        ),
                        Text('$_lastScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Network Safety Score', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(_rating, style: const TextStyle(color: _red)),
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
        _YesNoQuestion(
          title: 'Is this a public or shared network?',
          value: _publicNetwork,
          onChanged: (value) => setState(() => _publicNetwork = value),
        ),
        _YesNoQuestion(
          title: 'Did you verify the exact network name?',
          value: _verifiedName,
          onChanged: (value) => setState(() => _verifiedName = value),
        ),
        _YesNoQuestion(
          title: 'Is the network protected rather than completely open?',
          value: _securedNetwork,
          onChanged: (value) => setState(() => _securedNetwork = value),
        ),
        _YesNoQuestion(
          title: 'Is automatic connection to open networks disabled?',
          value: _autoJoinDisabled,
          onChanged: (value) => setState(() => _autoJoinDisabled = value),
        ),
        _YesNoQuestion(
          title: 'For sensitive activity, are you using a trusted connection such as cellular data or a reputable VPN?',
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
        const _GuidanceTile(
          Icons.phonelink_lock,
          'Keep auto-join restricted',
          'Prevent the device from silently reconnecting to open networks.',
        ),
        const _GuidanceTile(
          Icons.privacy_tip_outlined,
          'Use Private Wi-Fi Address when available',
          'Randomized device addressing can reduce passive tracking across networks.',
        ),
      ],
    );
  }
}

class _YesNoQuestion extends StatelessWidget {
  const _YesNoQuestion({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Yes')),
                ButtonSegment(value: false, label: Text('No')),
              ],
              selected: value == null ? <bool>{} : <bool>{value!},
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
  const _GuidanceTile(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: _red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
      ),
    );
  }
}
