import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exposure_center.dart';

void main() => runApp(const ShadowScanApp());

const red = Color(0xFFE31B23);
const surface = Color(0xFF12161C);
const background = Color(0xFF07090D);
const retakeWindow = Duration(days: 30);

class ShadowScanApp extends StatelessWidget {
  const ShadowScanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShadowScan Mobile',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: background,
          colorScheme: ColorScheme.fromSeed(seedColor: red, brightness: Brightness.dark, surface: surface),
          useMaterial3: true,
          cardTheme: const CardThemeData(color: surface, elevation: 0),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
          ),
        ),
        home: const AppBootstrap(),
      );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  AssessmentRecord? record;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('assessment_score');
    final date = prefs.getString('assessment_completed_at');
    final answers = prefs.getStringList('assessment_answers');
    if (score != null && date != null && answers != null) {
      record = AssessmentRecord(score: score, completedAt: DateTime.parse(date), answers: answers.map(int.parse).toList());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: red)));
    return record == null ? const SplashScreen() : DashboardScreen(record: record!);
  }
}

class QsbLogo extends StatelessWidget {
  const QsbLogo({super.key, this.size = 190});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset('assets/images/qsb_logo.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Spacer(),
              const QsbLogo(size: 280),
              const SizedBox(height: 18),
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
            ]),
          ),
        ),
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your privacy. Our priority.')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Center(child: QsbLogo(size: 150)),
          const InfoTile(Icons.lock_outline, 'Private by design', 'ShadowScan only asks for information needed to produce your security posture.'),
          const InfoTile(Icons.visibility_off_outlined, 'No password collection', 'Never enter a password into ShadowScan.'),
          const InfoTile(Icons.tune, 'Transparent scoring', 'Your Shadow Score is calculated from your answers.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentScreen())),
            child: const Text('CONTINUE TO ASSESSMENT'),
          ),
        ]),
      );
}

class InfoTile extends StatelessWidget {
  const InfoTile(this.icon, this.title, this.body, {super.key});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(child: ListTile(leading: Icon(icon, color: red), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(body))),
      );
}

class Remediation {
  const Remediation(this.title, this.severity, this.why, this.steps);
  final String title;
  final String severity;
  final String why;
  final List<String> steps;
}

class AssessmentQuestion {
  const AssessmentQuestion(this.title, this.detail, this.options, this.points, this.remediation);
  final String title;
  final String detail;
  final List<String> options;
  final List<int> points;
  final Remediation remediation;
}

const questions = <AssessmentQuestion>[
  AssessmentQuestion('Do you use a password manager?', 'Password managers make unique passwords easier to maintain.', ['Yes', 'Sometimes', 'No'], [15, 7, 0], Remediation('Start using a password manager', 'High', 'Unique passwords prevent one breach from compromising several accounts.', ['Choose a reputable password manager.', 'Replace reused passwords.', 'Protect the manager with MFA.'])),
  AssessmentQuestion('Is MFA enabled on your primary email?', 'Your email controls password resets for many accounts.', ['Yes', 'Some accounts', 'No'], [20, 8, 0], Remediation('Protect your primary email with MFA', 'Critical', 'Your email can reset passwords for other services.', ['Enable authenticator-app or passkey MFA.', 'Save recovery codes.', 'Review recent sign-ins.'])),
  AssessmentQuestion('Do you reuse passwords?', 'One breach can affect multiple accounts.', ['Never', 'Sometimes', 'Often'], [15, 7, 0], Remediation('Eliminate password reuse', 'High', 'Attackers test stolen passwords across many sites.', ['Change reused passwords.', 'Prioritize email and financial accounts.', 'Generate unique passwords.'])),
  AssessmentQuestion('Are automatic updates enabled?', 'Updates close known vulnerabilities.', ['Yes', 'Not sure', 'No'], [12, 5, 0], Remediation('Enable automatic updates', 'Medium', 'Outdated software may contain known exploitable flaws.', ['Enable system updates.', 'Enable app updates.', 'Remove unsupported apps.'])),
  AssessmentQuestion('Do you use a screen lock or biometrics?', 'A device lock protects lost devices.', ['Yes', 'Sometimes', 'No'], [10, 4, 0], Remediation('Secure your lock screen', 'High', 'Unlocked devices expose personal data.', ['Set a strong passcode.', 'Enable biometrics.', 'Hide notification previews.'])),
  AssessmentQuestion('Do you regularly back up important data?', 'Backups reduce loss and ransomware impact.', ['Yes', 'Sometimes', 'No'], [13, 6, 0], Remediation('Create reliable backups', 'Medium', 'Backups help recovery from deletion, theft, and ransomware.', ['Enable encrypted backup.', 'Keep a separate copy.', 'Test restoration.'])),
  AssessmentQuestion('How often do you use public Wi-Fi without a VPN?', 'Open networks increase interception risk.', ['Rarely', 'Sometimes', 'Often'], [15, 7, 0], Remediation('Reduce public Wi-Fi exposure', 'Medium', 'Public networks can be impersonated or monitored.', ['Prefer cellular data.', 'Verify network names.', 'Avoid sensitive activity.'])),
];

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key, this.isRetake = false});
  final bool isRetake;
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int index = 0;
  final answers = List<int?>.filled(questions.length, null);

  Future<void> next() async {
    if (answers[index] == null) return;
    if (index < questions.length - 1) {
      setState(() => index++);
      return;
    }
    final score = List.generate(questions.length, (i) => questions[i].points[answers[i]!]).fold<int>(0, (a, b) => a + b);
    final record = AssessmentRecord(score: score, answers: answers.cast<int>(), completedAt: DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('assessment_score', score);
    await prefs.setStringList('assessment_answers', record.answers.map((e) => '$e').toList());
    await prefs.setString('assessment_completed_at', record.completedAt.toIso8601String());
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => DashboardScreen(record: record)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.isRetake ? 'Retake assessment' : 'Cybersecurity assessment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinearProgressIndicator(value: (index + 1) / questions.length, color: red),
          const SizedBox(height: 10),
          Text('${index + 1} of ${questions.length}'),
          const SizedBox(height: 28),
          Text(q.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(q.detail, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ...List.generate(q.options.length, (i) => Card(child: RadioListTile<int>(value: i, groupValue: answers[index], activeColor: red, title: Text(q.options[i]), onChanged: (value) => setState(() => answers[index] = value)))),
          const Spacer(),
          FilledButton(onPressed: answers[index] == null ? null : next, child: Text(index == questions.length - 1 ? 'SAVE MY SHADOW SCORE' : 'NEXT')),
        ]),
      ),
    );
  }
}

class AssessmentRecord {
  const AssessmentRecord({required this.score, required this.answers, required this.completedAt});
  final int score;
  final List<int> answers;
  final DateTime completedAt;
  DateTime get nextRetake => completedAt.add(retakeWindow);
  bool get canRetake => !DateTime.now().isBefore(nextRetake);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.record});
  final AssessmentRecord record;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final findingIndexes = <int>[];
    for (var i = 0; i < widget.record.answers.length; i++) {
      if (questions[i].points[widget.record.answers[i]] < questions[i].points.first * .75) findingIndexes.add(i);
    }
    final pages = [
      HomePage(score: widget.record.score, findingIndexes: findingIndexes),
      const ExposureCenter(),
      const PlaceholderPage(Icons.wifi, 'Wi-Fi safety', 'Platform-permitted network safety checks will be implemented here.'),
      const LearnPage(),
      SettingsPage(record: widget.record),
    ];
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Row(children: [QsbLogo(size: 54), SizedBox(width: 12), Text('ShadowScan')])),
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        indicatorColor: red.withValues(alpha: .25),
        onDestinationSelected: (value) => setState(() => selected = value),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.score, required this.findingIndexes});
  final int score;
  final List<int> findingIndexes;
  String get risk => score >= 85 ? 'Low risk' : score >= 65 ? 'Moderate risk' : score >= 45 ? 'Elevated risk' : 'High risk';

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 120), children: [
        const Text('Your digital-risk posture', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          SizedBox(width: 94, height: 94, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: score / 100, strokeWidth: 9, color: red, backgroundColor: Colors.white12), Text('$score', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))])),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Shadow Score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(risk, style: const TextStyle(color: red, fontWeight: FontWeight.w700)), const Text('Based on your security assessment.')])),
        ]))),
        const SizedBox(height: 18),
        const Text('Priority actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (findingIndexes.isEmpty)
          const Card(child: ListTile(leading: Icon(Icons.verified_user_outlined, color: red), title: Text('Strong assessment results')))
        else
          ...findingIndexes.take(3).map((i) => Card(child: ListTile(leading: const Icon(Icons.warning_amber, color: red), title: Text(questions[i].remediation.title), subtitle: Text('${questions[i].remediation.severity} priority'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemediationScreen(remediation: questions[i].remediation))))))),
        const SizedBox(height: 12),
        const DailyTipCard(),
      ]);
}

class RemediationScreen extends StatelessWidget {
  const RemediationScreen({super.key, required this.remediation});
  final Remediation remediation;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Priority action')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(remediation.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          Chip(label: Text('${remediation.severity} severity')),
          const SizedBox(height: 20),
          Text(remediation.why, style: const TextStyle(fontSize: 17, height: 1.45)),
          const SizedBox(height: 20),
          ...remediation.steps.asMap().entries.map((entry) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: red, child: Text('${entry.key + 1}')), title: Text(entry.value)))),
        ]),
      );
}

class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.lightbulb_outline, color: red), SizedBox(width: 8), Text('Cyber Tip of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]), SizedBox(height: 12), Text('Never approve an MFA prompt you did not initiate.', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('Deny unexpected prompts and review recent sign-ins.')])));
}

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 120), children: const [
        Text('Learn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        SizedBox(height: 12),
        DailyTipCard(),
        SizedBox(height: 16),
        LearnTile(Icons.password, 'Passwords', 'Use unique credentials and a password manager.'),
        LearnTile(Icons.phishing, 'Phishing', 'Recognize deceptive messages and urgent requests.'),
        LearnTile(Icons.wifi_lock, 'Public Wi-Fi', 'Reduce risk on shared networks.'),
        LearnTile(Icons.verified_user_outlined, 'Multi-factor authentication', 'Protect important accounts with another factor.'),
      ]);
}

class LearnTile extends StatelessWidget {
  const LearnTile(this.icon, this.title, this.summary, {super.key});
  final IconData icon;
  final String title;
  final String summary;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: red), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(summary)));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.record});
  final AssessmentRecord record;
  String date(DateTime value) => '${value.month}/${value.day}/${value.year}';
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 120), children: [
        const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Assessment status', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text('Last assessment: ${date(record.completedAt)}'),
          Text('Next assessment available: ${date(record.nextRetake)}'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: record.canRetake ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentScreen(isRetake: true))) : null, icon: const Icon(Icons.refresh), label: Text(record.canRetake ? 'RETAKE ASSESSMENT' : 'RETAKE AVAILABLE IN 30 DAYS')),
        ]))),
        const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined, color: red), title: Text('Privacy'), subtitle: Text('Assessment and verified identity references are stored on this device.'))),
      ]);
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage(this.icon, this.title, this.message, {super.key});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58, color: red), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center)])));
}
