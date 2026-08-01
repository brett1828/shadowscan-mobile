import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ShadowScanApp());

const _red = Color(0xFFE31B23);
const _surface = Color(0xFF12161C);
const _background = Color(0xFF07090D);
const _retakeWindow = Duration(days: 30);

class ShadowScanApp extends StatelessWidget {
  const ShadowScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShadowScan Mobile',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _red,
          brightness: Brightness.dark,
          surface: _surface,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;
  AssessmentRecord? _record;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('assessment_score');
    final completedAt = prefs.getString('assessment_completed_at');
    final answers = prefs.getStringList('assessment_answers');

    if (score != null && completedAt != null && answers != null) {
      _record = AssessmentRecord(
        score: score,
        answers: answers.map(int.parse).toList(),
        completedAt: DateTime.parse(completedAt),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _red)),
      );
    }

    return _record == null
        ? const SplashScreen()
        : DashboardScreen(record: _record!);
  }
}

class QsbLogo extends StatelessWidget {
  const QsbLogo({super.key, this.size = 190});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/qsb_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.shield_outlined,
          color: _red,
          size: 72,
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const QsbLogo(size: 280),
              const SizedBox(height: 18),
              const Text(
                'SHADOWSCAN',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'MOBILE',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 8,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Personal cybersecurity. Everyday protection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.white70),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                child: const Text('GET STARTED'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quantum Shadow BlackOps',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your privacy. Our priority.')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: QsbLogo(size: 150)),
          const SizedBox(height: 18),
          const _InfoTile(
            icon: Icons.lock_outline,
            title: 'Private by design',
            body: 'ShadowScan only asks for information needed to produce your security posture.',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.visibility_off_outlined,
            title: 'No password collection',
            body: 'Never enter a password into ShadowScan. The assessment only asks about security habits.',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.tune,
            title: 'Transparent scoring',
            body: 'Your initial Shadow Score is calculated from your answers and every deduction is explainable.',
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Some Wi-Fi and device checks may be limited on iPhone because of Apple platform restrictions.'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssessmentScreen()),
            ),
            child: const Text('CONTINUE TO ASSESSMENT'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _red.withValues(alpha: .15),
          child: Icon(icon, color: _red),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(body),
      ),
    );
  }
}

class AssessmentQuestion {
  const AssessmentQuestion(this.title, this.detail, this.options, this.points);

  final String title;
  final String detail;
  final List<String> options;
  final List<int> points;
}

const _questions = <AssessmentQuestion>[
  AssessmentQuestion('Do you use a password manager?', 'Password managers make unique passwords easier to maintain.', ['Yes', 'Sometimes', 'No'], [15, 7, 0]),
  AssessmentQuestion('Is MFA enabled on your primary email?', 'Your email controls password resets for many other accounts.', ['Yes', 'Some accounts', 'No'], [20, 8, 0]),
  AssessmentQuestion('Do you reuse passwords?', 'Reused passwords allow one breach to affect multiple accounts.', ['Never', 'Sometimes', 'Often'], [15, 7, 0]),
  AssessmentQuestion('Are automatic updates enabled?', 'Updates close known security vulnerabilities.', ['Yes', 'Not sure', 'No'], [12, 5, 0]),
  AssessmentQuestion('Do you use a screen lock or biometrics?', 'A device lock helps protect your information if the device is lost.', ['Yes', 'Sometimes', 'No'], [10, 4, 0]),
  AssessmentQuestion('Do you regularly back up important data?', 'Backups reduce the impact of ransomware, loss, and device failure.', ['Yes', 'Sometimes', 'No'], [13, 6, 0]),
  AssessmentQuestion('How often do you use public Wi-Fi without a VPN?', 'Open networks can increase interception and impersonation risk.', ['Rarely', 'Sometimes', 'Often'], [15, 7, 0]),
];

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key, this.isRetake = false});

  final bool isRetake;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _index = 0;
  final List<int?> _answers = List<int?>.filled(_questions.length, null);

  Future<void> _next() async {
    if (_answers[_index] == null) return;

    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }

    final score = List.generate(
      _questions.length,
      (i) => _questions[i].points[_answers[i]!],
    ).fold<int>(0, (a, b) => a + b);

    final record = AssessmentRecord(
      score: score,
      answers: _answers.cast<int>(),
      completedAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('assessment_score', score);
    await prefs.setStringList(
      'assessment_answers',
      record.answers.map((value) => '$value').toList(),
    );
    await prefs.setString(
      'assessment_completed_at',
      record.completedAt.toIso8601String(),
    );

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(record: record)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];

    return Scaffold(
      appBar: AppBar(title: Text(widget.isRetake ? 'Retake assessment' : 'Cybersecurity assessment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              color: _red,
            ),
            const SizedBox(height: 10),
            Text('${_index + 1} of ${_questions.length}'),
            const SizedBox(height: 28),
            Text(question.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(question.detail, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ...List.generate(
              question.options.length,
              (optionIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: RadioListTile<int>(
                    value: optionIndex,
                    groupValue: _answers[_index],
                    activeColor: _red,
                    title: Text(question.options[optionIndex]),
                    onChanged: (value) => setState(() => _answers[_index] = value),
                  ),
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _answers[_index] == null ? null : _next,
              child: Text(_index == _questions.length - 1 ? 'SAVE MY SHADOW SCORE' : 'NEXT'),
            ),
          ],
        ),
      ),
    );
  }
}

class AssessmentRecord {
  const AssessmentRecord({required this.score, required this.answers, required this.completedAt});

  final int score;
  final List<int> answers;
  final DateTime completedAt;

  DateTime get nextRetake => completedAt.add(_retakeWindow);
  bool get canRetake => !DateTime.now().isBefore(nextRetake);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.record});

  final AssessmentRecord record;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final findings = <String>[];
    for (var i = 0; i < widget.record.answers.length; i++) {
      if (_questions[i].points[widget.record.answers[i]] < (_questions[i].points.first * .75)) {
        findings.add(_questions[i].title);
      }
    }

    final pages = [
      _HomePage(score: widget.record.score, findings: findings),
      const _PlaceholderPage(icon: Icons.public, title: 'Exposure', message: 'Verified email breach monitoring will be connected in a later backend phase.'),
      const _PlaceholderPage(icon: Icons.wifi, title: 'Wi-Fi safety', message: 'Platform-permitted network safety checks will be implemented here.'),
      const _PlaceholderPage(icon: Icons.school_outlined, title: 'Learn', message: 'Daily tips, awareness lessons, and micro-quizzes will live here.'),
      _SettingsPage(record: widget.record),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            QsbLogo(size: 54),
            SizedBox(width: 12),
            Text('ShadowScan'),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: _red.withValues(alpha: .25),
        onDestinationSelected: (value) => setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Exposure'),
          NavigationDestination(icon: Icon(Icons.wifi), label: 'Wi-Fi'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.score, required this.findings});

  final int score;
  final List<String> findings;

  String get risk {
    if (score >= 85) return 'Low risk';
    if (score >= 65) return 'Moderate risk';
    if (score >= 45) return 'Elevated risk';
    return 'High risk';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const Text('Your digital-risk posture', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: score / 100, strokeWidth: 9, color: _red, backgroundColor: Colors.white12),
                      Text('$score', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shadow Score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(risk, style: const TextStyle(color: _red, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 7),
                      const Text('Based on your seven-question personal security assessment.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Priority actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (findings.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined, color: _red),
              title: Text('Strong assessment results'),
              subtitle: Text('Continue reviewing your settings and stay alert for new threats.'),
            ),
          )
        else
          ...findings.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.warning_amber)),
                      title: Text(item),
                      subtitle: const Text('Review this habit to improve your Shadow Score.'),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: _red),
                    SizedBox(width: 8),
                    Text('Cyber Tip of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                SizedBox(height: 12),
                Text('Never approve an MFA prompt you did not initiate.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Deny unexpected prompts, change the affected password, and review recent sign-ins.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.record});

  final AssessmentRecord record;

  String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assessment status', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('Last assessment: ${_date(record.completedAt)}'),
                const SizedBox(height: 6),
                Text('Next assessment available: ${_date(record.nextRetake)}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: record.canRetake
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AssessmentScreen(isRetake: true)),
                          )
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(record.canRetake ? 'RETAKE ASSESSMENT' : 'RETAKE AVAILABLE IN 30 DAYS'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: _red),
            title: Text('Privacy'),
            subtitle: Text('Assessment results are currently stored only on this device.'),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: _red),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
