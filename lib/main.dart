import 'package:flutter/material.dart';

void main() => runApp(const ShadowScanApp());

class ShadowScanApp extends StatelessWidget {
  const ShadowScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7CFF6B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShadowScan',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF11161D),
        ),
        scaffoldBackgroundColor: const Color(0xFF080B10),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: Color(0xFF11161D),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.title,
    required this.detail,
    required this.weight,
    required this.action,
    required this.icon,
  });

  final String title;
  final String detail;
  final int weight;
  final String action;
  final IconData icon;
}

const assessmentQuestions = <AssessmentQuestion>[
  AssessmentQuestion(
    title: 'Do you use unique passwords for important accounts?',
    detail: 'Reused passwords allow one breach to compromise multiple accounts.',
    weight: 18,
    action: 'Replace reused passwords and begin using a password manager.',
    icon: Icons.password,
  ),
  AssessmentQuestion(
    title: 'Is MFA enabled on your primary email account?',
    detail: 'Your email can be used to reset access to many other accounts.',
    weight: 20,
    action: 'Enable authenticator-app or security-key MFA on your primary email.',
    icon: Icons.phonelink_lock,
  ),
  AssessmentQuestion(
    title: 'Do you use a password manager?',
    detail: 'Password managers make strong, unique credentials easier to maintain.',
    weight: 12,
    action: 'Choose a reputable password manager and secure it with MFA.',
    icon: Icons.key,
  ),
  AssessmentQuestion(
    title: 'Are automatic software updates enabled?',
    detail: 'Updates frequently repair known security vulnerabilities.',
    weight: 14,
    action: 'Enable automatic operating-system and application updates.',
    icon: Icons.system_update,
  ),
  AssessmentQuestion(
    title: 'Is your device protected by a lock and biometrics?',
    detail: 'A strong lock limits access if the device is lost or stolen.',
    weight: 12,
    action: 'Enable a strong PIN or passcode and biometric unlock.',
    icon: Icons.fingerprint,
  ),
  AssessmentQuestion(
    title: 'Do you back up important files regularly?',
    detail: 'Reliable backups reduce the impact of theft, failure, and ransomware.',
    weight: 12,
    action: 'Create an encrypted cloud or offline backup routine.',
    icon: Icons.cloud_done_outlined,
  ),
  AssessmentQuestion(
    title: 'Do you avoid sensitive activity on untrusted public Wi-Fi?',
    detail: 'Public networks may expose traffic to monitoring or impersonation.',
    weight: 12,
    action: 'Use trusted cellular data or a reputable VPN on public Wi-Fi.',
    icon: Icons.wifi_lock,
  ),
];

class AssessmentResult {
  const AssessmentResult({required this.score, required this.answers});
  final int score;
  final List<bool> answers;

  List<int> get failedIndexes => [
        for (var i = 0; i < answers.length; i++)
          if (!answers[i]) i,
      ];
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final answers = List<bool?>.filled(assessmentQuestions.length, null);

  void next() {
    if (step == 0) {
      setState(() => step = 1);
      return;
    }
    final questionIndex = step - 1;
    if (answers[questionIndex] == null) return;
    if (questionIndex < assessmentQuestions.length - 1) {
      setState(() => step++);
      return;
    }
    final completed = answers.cast<bool>();
    var score = 0;
    for (var i = 0; i < completed.length; i++) {
      if (completed[i]) score += assessmentQuestions[i].weight;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          result: AssessmentResult(score: score, answers: completed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Icon(Icons.shield_moon_outlined,
                    size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                const Text('Know your digital risk.',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const Text(
                  'Complete a short personal-security assessment to generate your first transparent Shadow Score and prioritized action plan.',
                  style: TextStyle(fontSize: 17, height: 1.45),
                ),
                const SizedBox(height: 18),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This prototype calculates your score locally from your answers. It does not collect passwords or scan accounts.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: next,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text('Start assessment'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final index = step - 1;
    final question = assessmentQuestions[index];
    final progress = (index + 1) / assessmentQuestions.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => step--),
        ),
        title: Text('Assessment ${index + 1} of ${assessmentQuestions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 34),
              Icon(question.icon,
                  size: 52, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 22),
              Text(question.title,
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w750)),
              const SizedBox(height: 14),
              Text(question.detail,
                  style: const TextStyle(fontSize: 16, height: 1.45)),
              const SizedBox(height: 28),
              _AnswerTile(
                label: 'Yes',
                selected: answers[index] == true,
                onTap: () => setState(() => answers[index] = true),
              ),
              const SizedBox(height: 12),
              _AnswerTile(
                label: 'No or not sure',
                selected: answers[index] == false,
                onTap: () => setState(() => answers[index] = false),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: answers[index] == null ? null : next,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(index == assessmentQuestions.length - 1
                        ? 'Calculate Shadow Score'
                        : 'Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        selected: selected,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.result});
  final AssessmentResult result;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomePage(result: widget.result),
      const _PlaceholderPage(
        icon: Icons.public,
        title: 'Exposure',
        message: 'Verified identity and breach-monitoring services will live here.',
      ),
      const _PlaceholderPage(
        icon: Icons.wifi_tethering,
        title: 'Wi-Fi Safety',
        message: 'Platform-permitted network checks and safety guidance will live here.',
      ),
      const _LearnPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.shield_moon_outlined),
          SizedBox(width: 10),
          Text('ShadowScan'),
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
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
  const _HomePage({required this.result});
  final AssessmentResult result;

  String get riskLabel {
    if (result.score >= 85) return 'Low risk';
    if (result.score >= 65) return 'Moderate risk';
    if (result.score >= 40) return 'Elevated risk';
    return 'High risk';
  }

  @override
  Widget build(BuildContext context) {
    final failures = result.failedIndexes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text('Your digital-risk posture',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _ScoreCard(score: result.score, riskLabel: riskLabel),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Priority actions'),
        const SizedBox(height: 10),
        if (failures.isEmpty)
          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.verified_user_outlined)),
              title: Text('No assessment gaps found'),
              subtitle: Text('Continue reviewing your posture as your accounts and devices change.'),
            ),
          )
        else
          ...failures.take(3).map((index) {
            final item = assessmentQuestions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(item.icon)),
                  title: Text(item.action,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.weight}-point posture gap'),
                ),
              ),
            );
          }),
        const SizedBox(height: 6),
        const _DailyTipCard(),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'How your score works'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Your current ${result.score}/100 score is the sum of seven weighted security controls. Reading tips does not raise the score; only improving security practices does.',
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.riskLabel});
  final int score;
  final String riskLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$score',
                        style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
                    const Text('/100', style: TextStyle(fontSize: 11)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shadow Score',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(riskLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  const Text('Based on your completed personal-security assessment.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Cyber Tip of the Day',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          const Text('Never approve an MFA prompt you did not initiate.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
              'Deny the request, change your password, and review recent sign-ins. Repeated prompts may be an MFA-fatigue attack.'),
          const SizedBox(height: 12),
          const Wrap(spacing: 8, children: [
            Chip(label: Text('Account security')),
            Chip(label: Text('Easy action')),
          ]),
        ]),
      ),
    );
  }
}

class _LearnPage extends StatelessWidget {
  const _LearnPage();
  @override
  Widget build(BuildContext context) {
    const topics = [
      ('Phishing defense', Icons.phishing),
      ('Password security', Icons.password),
      ('Public Wi-Fi safety', Icons.wifi_lock),
      ('Privacy and identity', Icons.privacy_tip_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Build safer digital habits',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Daily guidance and short awareness lessons.'),
        const SizedBox(height: 18),
        const _DailyTipCard(),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Awareness topics'),
        const SizedBox(height: 10),
        ...topics.map((topic) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(topic.$2)),
                  title: Text(topic.$1),
                  subtitle: const Text('Lesson content coming next'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            )),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
