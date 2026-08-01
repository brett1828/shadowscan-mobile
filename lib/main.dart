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
  Widget build(BuildContext context) => MaterialApp(
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
          cardTheme: const CardThemeData(color: _surface, elevation: 0),
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
      record = AssessmentRecord(
        score: score,
        completedAt: DateTime.parse(date),
        answers: answers.map(int.parse).toList(),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _red)));
    }
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
        child: Image.asset(
          'assets/images/qsb_logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, color: _red),
        ),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
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
              ],
            ),
          ),
        ),
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your privacy. Our priority.')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: QsbLogo(size: 150)),
            const SizedBox(height: 18),
            const InfoTile(Icons.lock_outline, 'Private by design', 'ShadowScan only asks for information needed to produce your security posture.'),
            const InfoTile(Icons.visibility_off_outlined, 'No password collection', 'Never enter a password into ShadowScan. The assessment only asks about security habits.'),
            const InfoTile(Icons.tune, 'Transparent scoring', 'Your initial Shadow Score is calculated from your answers and every deduction is explainable.'),
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

class InfoTile extends StatelessWidget {
  const InfoTile(this.icon, this.title, this.body, {super.key});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: _red.withValues(alpha: .15), child: Icon(icon, color: _red)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(body),
          ),
        ),
      );
}

class AssessmentQuestion {
  const AssessmentQuestion(this.title, this.detail, this.options, this.points, this.remediation);
  final String title;
  final String detail;
  final List<String> options;
  final List<int> points;
  final Remediation remediation;
}

class Remediation {
  const Remediation(this.title, this.severity, this.why, this.steps);
  final String title;
  final String severity;
  final String why;
  final List<String> steps;
}

const questions = <AssessmentQuestion>[
  AssessmentQuestion('Do you use a password manager?', 'Password managers make unique passwords easier to maintain.', ['Yes', 'Sometimes', 'No'], [15, 7, 0], Remediation('Start using a password manager', 'High', 'Unique passwords prevent one breach from compromising several accounts.', ['Choose a reputable password manager.', 'Import or save your most important accounts first.', 'Replace reused passwords with unique generated passwords.', 'Protect the password manager with MFA.'])),
  AssessmentQuestion('Is MFA enabled on your primary email?', 'Your email controls password resets for many other accounts.', ['Yes', 'Some accounts', 'No'], [20, 8, 0], Remediation('Protect your primary email with MFA', 'Critical', 'Your email account can be used to reset passwords for banking, social media, and other services.', ['Open your email security settings.', 'Enable authenticator-app or passkey MFA.', 'Save recovery codes somewhere secure.', 'Review recent sign-ins and connected devices.'])),
  AssessmentQuestion('Do you reuse passwords?', 'Reused passwords allow one breach to affect multiple accounts.', ['Never', 'Sometimes', 'Often'], [15, 7, 0], Remediation('Eliminate password reuse', 'High', 'Attackers test stolen passwords across many websites in credential-stuffing attacks.', ['Identify accounts sharing the same password.', 'Change your email and financial accounts first.', 'Generate a unique password for every account.', 'Monitor your email for breach notices.'])),
  AssessmentQuestion('Are automatic updates enabled?', 'Updates close known security vulnerabilities.', ['Yes', 'Not sure', 'No'], [12, 5, 0], Remediation('Enable automatic updates', 'Medium', 'Outdated devices and apps may contain vulnerabilities that already have public exploits.', ['Enable automatic operating-system updates.', 'Enable automatic app-store updates.', 'Restart devices regularly to finish installations.', 'Remove unsupported apps and devices.'])),
  AssessmentQuestion('Do you use a screen lock or biometrics?', 'A device lock helps protect your information if the device is lost.', ['Yes', 'Sometimes', 'No'], [10, 4, 0], Remediation('Secure your device lock screen', 'High', 'An unlocked lost device can expose email, messages, saved passwords, and financial apps.', ['Set a strong device passcode.', 'Enable Face ID, Touch ID, or fingerprint unlock.', 'Reduce the automatic-lock timeout.', 'Hide sensitive notification previews.'])),
  AssessmentQuestion('Do you regularly back up important data?', 'Backups reduce the impact of ransomware, loss, and device failure.', ['Yes', 'Sometimes', 'No'], [13, 6, 0], Remediation('Create reliable backups', 'Medium', 'Backups help recover from ransomware, accidental deletion, theft, and hardware failure.', ['Enable encrypted cloud backup.', 'Back up important photos and documents.', 'Keep one copy separate from your primary device.', 'Test that files can be restored.'])),
  AssessmentQuestion('How often do you use public Wi-Fi without a VPN?', 'Open networks can increase interception and impersonation risk.', ['Rarely', 'Sometimes', 'Often'], [15, 7, 0], Remediation('Reduce public Wi-Fi exposure', 'Medium', 'Public networks may be impersonated or shared with untrusted users.', ['Prefer cellular data for sensitive activity.', 'Verify the exact network name with staff.', 'Avoid banking or password changes on public Wi-Fi.', 'Use an established VPN when appropriate.'])),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (index + 1) / questions.length, color: _red),
            const SizedBox(height: 10),
            Text('${index + 1} of ${questions.length}'),
            const SizedBox(height: 28),
            Text(q.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(q.detail, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ...List.generate(q.options.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: answers[index],
                      activeColor: _red,
                      title: Text(q.options[i]),
                      onChanged: (value) => setState(() => answers[index] = value),
                    ),
                  ),
                )),
            const Spacer(),
            FilledButton(onPressed: answers[index] == null ? null : next, child: Text(index == questions.length - 1 ? 'SAVE MY SHADOW SCORE' : 'NEXT')),
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
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final findingIndexes = <int>[];
    for (var i = 0; i < widget.record.answers.length; i++) {
      if (questions[i].points[widget.record.answers[i]] < questions[i].points.first * .75) findingIndexes.add(i);
    }
    final pages = [
      HomePage(score: widget.record.score, findingIndexes: findingIndexes),
      const PlaceholderPage(Icons.public, 'Exposure', 'Verified email breach monitoring will be connected in a later backend phase.'),
      const PlaceholderPage(Icons.wifi, 'Wi-Fi safety', 'Platform-permitted network safety checks will be implemented here.'),
      const LearnPage(),
      SettingsPage(record: widget.record),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(children: [QsbLogo(size: 54), SizedBox(width: 12), Text('ShadowScan')]),
      ),
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        indicatorColor: _red.withValues(alpha: .25),
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
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
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
          if (findingIndexes.isEmpty)
            const Card(child: ListTile(leading: Icon(Icons.verified_user_outlined, color: _red), title: Text('Strong assessment results'), subtitle: Text('Continue reviewing your settings and stay alert for new threats.')))
          else
            ...findingIndexes.take(3).map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.warning_amber)),
                      title: Text(questions[i].remediation.title),
                      subtitle: Text('${questions[i].remediation.severity} priority'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemediationScreen(remediation: questions[i].remediation))),
                    ),
                  ),
                )),
          const SizedBox(height: 8),
          const DailyTipCard(),
        ],
      );
}

class RemediationScreen extends StatelessWidget {
  const RemediationScreen({super.key, required this.remediation});
  final Remediation remediation;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Priority action')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(remediation.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Chip(label: Text('${remediation.severity} severity'), avatar: const Icon(Icons.warning_amber, color: _red)),
            const SizedBox(height: 20),
            const Text('Why this matters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(remediation.why, style: const TextStyle(fontSize: 17, height: 1.45)),
            const SizedBox(height: 24),
            const Text('Recommended steps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...remediation.steps.asMap().entries.map((entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: _red, foregroundColor: Colors.white, child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                )),
          ],
        ),
      );
}

class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});

  @override
  Widget build(BuildContext context) => const Card(
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
      );
}

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        children: [
          const Text('Learn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Build safer digital habits one lesson at a time.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          const DailyTipCard(),
          const SizedBox(height: 18),
          const Text('Awareness categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const LearnTile(Icons.password, 'Passwords', 'Create unique credentials and use a password manager.', ['Use at least 14 characters when creating passwords manually.', 'Never reuse your primary email password.', 'Store recovery codes securely.']),
          const LearnTile(Icons.phishing, 'Phishing', 'Recognize deceptive messages, links, and urgent requests.', ['Slow down when a message creates urgency.', 'Verify payment or login requests through another channel.', 'Inspect the sender and destination before acting.']),
          const LearnTile(Icons.wifi_lock, 'Public Wi-Fi', 'Reduce risk on shared and unfamiliar networks.', ['Confirm the exact network name.', 'Prefer cellular data for sensitive tasks.', 'Turn off automatic Wi-Fi connection.']),
          const LearnTile(Icons.verified_user_outlined, 'Multi-factor authentication', 'Add a second layer of protection to important accounts.', ['Prefer passkeys or authenticator apps.', 'Never approve an unexpected prompt.', 'Keep recovery options current.']),
          const SizedBox(height: 18),
          const Text('Quick knowledge check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const QuizCard(),
        ],
      );
}

class LearnTile extends StatelessWidget {
  const LearnTile(this.icon, this.title, this.summary, this.points, {super.key});
  final IconData icon;
  final String title;
  final String summary;
  final List<String> points;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: _red),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(title: title, summary: summary, points: points, icon: icon))),
          ),
        ),
      );
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.title, required this.summary, required this.points, required this.icon});
  final String title;
  final String summary;
  final List<String> points;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(icon, size: 64, color: _red),
            const SizedBox(height: 18),
            Text(summary, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ...points.asMap().entries.map((entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: _red, child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                )),
          ],
        ),
      );
}

class QuizCard extends StatefulWidget {
  const QuizCard({super.key});

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? selected;
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    const options = ['Approve it quickly', 'Deny it and review account security', 'Ignore every future MFA prompt'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('You receive an MFA prompt you did not initiate. What should you do?', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...List.generate(options.length, (i) => RadioListTile<int>(value: i, groupValue: selected, title: Text(options[i]), onChanged: (value) => setState(() { selected = value; checked = false; }))),
          FilledButton(onPressed: selected == null ? null : () => setState(() => checked = true), child: const Text('CHECK ANSWER')),
          if (checked) ...[
            const SizedBox(height: 12),
            Text(selected == 1 ? 'Correct. Deny the prompt and investigate the account.' : 'Not quite. Unexpected MFA prompts can indicate an attempted takeover.', style: TextStyle(color: selected == 1 ? Colors.greenAccent : _red, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.record});
  final AssessmentRecord record;
  String date(DateTime value) => '${value.month}/${value.day}/${value.year}';

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Assessment status', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('Last assessment: ${date(record.completedAt)}'),
                Text('Next assessment available: ${date(record.nextRetake)}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: record.canRetake ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentScreen(isRetake: true))) : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(record.canRetake ? 'RETAKE ASSESSMENT' : 'RETAKE AVAILABLE IN 30 DAYS'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined, color: _red), title: Text('Privacy'), subtitle: Text('Assessment results are currently stored only on this device.'))),
        ],
      );
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage(this.icon, this.title, this.message, {super.key});
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
            Text(message, textAlign: TextAlign.center),
          ]),
        ),
      );
}
