import 'package:flutter/material.dart';

void main() => runApp(const ShadowScanApp());

const _red = Color(0xFFE31B23);
const _surface = Color(0xFF12161C);

class ShadowScanApp extends StatelessWidget {
  const ShadowScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShadowScan Mobile',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07090D),
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
      home: const SplashScreen(),
    );
  }
}

class QsbLogo extends StatelessWidget {
  const QsbLogo({super.key, this.size = 190});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/qsb_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, error, __) => SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.shield_outlined, color: _red, size: 72),
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
              const QsbLogo(size: 240),
              const SizedBox(height: 22),
              const Text(
                'SHADOWSCAN',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const Text(
                'MOBILE',
                style: TextStyle(fontSize: 16, letterSpacing: 8, color: Colors.white70),
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
              const Text('Quantum Shadow BlackOps', style: TextStyle(color: Colors.white54)),
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
          const Center(child: QsbLogo(size: 130)),
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
              child: Text(
                'Some Wi-Fi and device checks may be limited on iPhone because of Apple platform restrictions.',
              ),
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
  const AssessmentScreen({super.key});
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _index = 0;
  final List<int?> _answers = List<int?>.filled(_questions.length, null);

  void _next() {
    if (_answers[_index] == null) return;
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    final score = List.generate(
      _questions.length,
      (i) => _questions[i].points[_answers[i]!],
    ).fold<int>(0, (a, b) => a + b);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(score: score, answers: _answers.cast<int>()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Cybersecurity assessment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_index + 1) / _questions.length, color: _red),
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
              child: Text(_index == _questions.length - 1 ? 'SEE MY SHADOW SCORE' : 'NEXT'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.score, required this.answers});
  final int score;
  final List<int> answers;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final findings = <String>[];
    for (var i = 0; i < widget.answers.length; i++) {
      if (_questions[i].points[widget.answers[i]] < _questions[i].points.first * .75) {
        findings.add(_questions[i].title);
      }
    }

    final pages = [
      _HomePage(score: widget.score, findings: findings),
      const _PlaceholderPage(icon: Icons.public, title: 'Exposure', message: 'Verified email breach monitoring will be connected in a later backend phase.'),
      const _PlaceholderPage(icon: Icons.wifi, title: 'Wi-Fi safety', message: 'Platform-permitted network safety checks will be implemented here.'),
      const _PlaceholderPage(icon: Icons.school_outlined, title: 'Learn', message: 'Daily tips, awareness lessons, and micro-quizzes will live here.'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [QsbLogo(size: 44), SizedBox(width: 10), Text('ShadowScan')],
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
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.score, required this.findings});
  final int score;
  final List<String> findings;

  String get risk => score >= 85 ? 'Low risk' : score >= 65 ? 'Moderate risk' : score >= 45 ? 'Elevated risk' : 'High risk';

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
