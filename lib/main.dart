import 'dart:convert';
import 'dart:typed_data';
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
        colorScheme: ColorScheme.fromSeed(seedColor: _red, brightness: Brightness.dark, surface: _surface),
        useMaterial3: true,
        cardTheme: const CardThemeData(color: _surface, elevation: 0, margin: EdgeInsets.zero),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
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
    final Uint8List bytes = base64Decode(_logoBase64);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
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
              const QsbLogo(size: 220),
              const SizedBox(height: 22),
              const Text('SHADOWSCAN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Text('MOBILE', style: TextStyle(fontSize: 16, letterSpacing: 8, color: Colors.white70)),
              const SizedBox(height: 18),
              const Text('Personal cybersecurity. Everyday protection.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.white70)),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
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
          const Center(child: QsbLogo(size: 115)),
          const SizedBox(height: 18),
          const _InfoTile(icon: Icons.lock_outline, title: 'Private by design', body: 'ShadowScan only asks for information needed to produce your security posture.'),
          const SizedBox(height: 12),
          const _InfoTile(icon: Icons.visibility_off_outlined, title: 'No password collection', body: 'Never enter a password into ShadowScan. The assessment only asks about security habits.'),
          const SizedBox(height: 12),
          const _InfoTile(icon: Icons.tune, title: 'Transparent scoring', body: 'Your initial Shadow Score is calculated from your answers and every deduction is explainable.'),
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Some Wi-Fi and device checks may be limited on iPhone because of Apple platform restrictions.'))),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentScreen())),
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
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: _red.withValues(alpha: .15), child: Icon(icon, color: _red)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(body),
        ),
      );
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
    } else {
      final score = List.generate(_questions.length, (i) => _questions[i].points[_answers[i]!]).fold<int>(0, (a, b) => a + b);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(score: score, answers: _answers.cast<int>())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Cybersecurity assessment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_index + 1) / _questions.length, color: _red),
            const SizedBox(height: 10),
            Text('${_index + 1} of ${_questions.length}', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 28),
            Text(q.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(q.detail, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 24),
            ...List.generate(q.options.length, (optionIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: RadioListTile<int>(
                      value: optionIndex,
                      groupValue: _answers[_index],
                      activeColor: _red,
                      title: Text(q.options[optionIndex], style: const TextStyle(fontWeight: FontWeight.w600)),
                      onChanged: (value) => setState(() => _answers[_index] = value),
                    ),
                  ),
                )),
            const Spacer(),
            FilledButton(onPressed: _answers[_index] == null ? null : _next, child: Text(_index == _questions.length - 1 ? 'SEE MY SHADOW SCORE' : 'NEXT')),
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
      if (_questions[i].points[widget.answers[i]] < (_questions[i].points.first * .75)) findings.add(_questions[i].title);
    }
    final pages = [
      _HomePage(score: widget.score, findings: findings),
      const _PlaceholderPage(icon: Icons.public, title: 'Exposure', message: 'Verified email breach monitoring will be connected in a later backend phase.'),
      const _PlaceholderPage(icon: Icons.wifi, title: 'Wi-Fi safety', message: 'Platform-permitted network safety checks will be implemented here.'),
      const _PlaceholderPage(icon: Icons.school_outlined, title: 'Learn', message: 'Daily tips, awareness lessons, and micro-quizzes will live here.'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [QsbLogo(size: 42), SizedBox(width: 10), Text('ShadowScan')]),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))],
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
            child: Row(children: [
              SizedBox(width: 94, height: 94, child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: score / 100, strokeWidth: 9, color: _red, backgroundColor: Colors.white12),
                Text('$score', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              ])),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Shadow Score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(risk, style: const TextStyle(color: _red, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                const Text('Based on your seven-question personal security assessment.'),
              ])),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Priority actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (findings.isEmpty)
          const Card(child: ListTile(leading: Icon(Icons.verified_user_outlined, color: _red), title: Text('Strong assessment results'), subtitle: Text('Continue reviewing your settings and stay alert for new threats.')))
        else
          ...findings.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.warning_amber)), title: Text(item), subtitle: const Text('Review this habit to improve your Shadow Score.'), trailing: const Icon(Icons.chevron_right))),
              )),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.lightbulb_outline, color: _red), SizedBox(width: 8), Text('Cyber Tip of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]),
              SizedBox(height: 12),
              Text('Never approve an MFA prompt you did not initiate.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Deny unexpected prompts, change the affected password, and review recent sign-ins.'),
            ]),
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 58, color: _red),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      );
}

const _logoBase64 = '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAEAAQADASIAAhEBAxEB/8QAHQABAAIDAQEBAQAAAAAAAAAAAAYHBAUIAwIBCf/EAFkQAAEEAQIDBAYDBw0MCQUAAAEAAgMEBQYRBxIhEzFBUQgUImFxgSMykRVSYnOSodIWFzNCQ3KCk5Wio8HRCRgkJShEY2aElLHwJic3RVNVVmSkdKXC0+P/xAAaAQEAAwEBAQAAAAAAAAAAAAAAAQIDBAUG/8QAOBEAAgECBAIIAwYGAwAAAAAAAAECAxEEEiExQVEFEyJhcYGRobHR8EJSksHS4QYUFTJigjNTcv/aAAwDAQACEQMRAD8A4yREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBFsMFg8znrgp4TFXslYPdFVgdK77GgqXfrW5ah7WrM3gNLNHV0d+819jb8RFzyb+4gJcsot7EBRWtpvROj79oQYWrrjXtgHbkw+M9VgJ8jI8SP29/IFa+l+CHEOw0S4jhBpLTMHf61qS667K0eZYXFo/iwouMvNnLVCjdvziCjTsWpT3MhjL3H5BSqDhfrp0DbFrAS4yuf3XJyx027ef0zmrpa/oaWlE+vqv0gYazIx9JjdJUAwM9x7DYD+E1Vhn8lwI0/cd2OntR6vutPWfLZQRtcfeItz8iE1J7JXY0VhaZP3b4g6erEfudES3pPh9Gzk/nrc4XReCuuAw+nde6rcP21ei2pCf4W0p2+xbiXi5fpgnR+idNaZj7mywY9hk/jJd9/sC0Uustda1zNTEZDWNyw+1M2NsfavdEzc9SWjZgAG5Ow7gqOpFcTojhK0rWja+19L+F9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';