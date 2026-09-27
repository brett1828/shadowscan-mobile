import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _red = Color(0xFFE31B23);

class LearnCenter extends StatefulWidget {
  const LearnCenter({super.key});

  @override
  State<LearnCenter> createState() => _LearnCenterState();
}

class _LearnCenterState extends State<LearnCenter> {
  Set<String> _completed = <String>{};

  static const lessons = <CyberLesson>[
    CyberLesson(
      id: 'passwords',
      icon: Icons.password,
      title: 'Passwords',
      summary: 'Create unique credentials and protect them with a password manager.',
      points: [
        'Use a unique password for every important account.',
        'Prefer long generated passwords instead of predictable variations.',
        'Protect your password manager with multi-factor authentication.',
        'Change exposed or reused passwords immediately after a known breach.',
      ],
    ),
    CyberLesson(
      id: 'phishing',
      icon: Icons.phishing,
      title: 'Phishing',
      summary: 'Recognize deceptive messages, links, attachments, and urgent requests.',
      points: [
        'Slow down when a message creates urgency or pressure.',
        'Verify payment, password-reset, and login requests through a separate channel.',
        'Inspect the sender and destination before opening links.',
        'Never provide an MFA code to someone who contacted you unexpectedly.',
      ],
    ),
    CyberLesson(
      id: 'public_wifi',
      icon: Icons.wifi_lock,
      title: 'Public Wi-Fi',
      summary: 'Reduce risk on shared and unfamiliar wireless networks.',
      points: [
        'Confirm the exact network name with staff before connecting.',
        'Prefer cellular data for sensitive transactions when practical.',
        'Disable automatic connection to open Wi-Fi networks.',
        'Keep HTTPS protections enabled and treat unexpected captive portals cautiously.',
      ],
    ),
    CyberLesson(
      id: 'mfa',
      icon: Icons.verified_user_outlined,
      title: 'Multi-factor authentication',
      summary: 'Add another layer of protection to high-value accounts.',
      points: [
        'Prefer passkeys, security keys, or authenticator apps where available.',
        'Never approve an MFA prompt you did not initiate.',
        'Keep recovery methods current and recovery codes protected.',
        'Enable MFA on your primary email before lower-value accounts.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('learn_completed_lessons') ?? const <String>[];
    if (mounted) setState(() => _completed = saved.toSet());
  }

  Future<void> _openLesson(CyberLesson lesson) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          initiallyCompleted: _completed.contains(lesson.id),
        ),
      ),
    );
    if (completed != true) return;
    final next = {..._completed, lesson.id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('learn_completed_lessons', next.toList());
    if (mounted) setState(() => _completed = next);
  }

  @override
  Widget build(BuildContext context) {
    final progress = lessons.isEmpty ? 0.0 : _completed.length / lessons.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        const Text('Learn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Build safer digital habits one lesson at a time.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_completed.length} of ${lessons.length} lessons completed',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress, color: _red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _DailyTipCard(),
        const SizedBox(height: 18),
        const Text('Awareness categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...lessons.map(
          (lesson) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: Icon(lesson.icon, color: _red),
                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(lesson.summary),
                trailing: _completed.contains(lesson.id)
                    ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                    : const Icon(Icons.chevron_right),
                onTap: () => _openLesson(lesson),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Quick knowledge check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const QuizCard(),
      ],
    );
  }
}

class CyberLesson {
  const CyberLesson({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.points,
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final List<String> points;
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lesson,
    required this.initiallyCompleted,
  });

  final CyberLesson lesson;
  final bool initiallyCompleted;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.initiallyCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(widget.lesson.icon, size: 64, color: _red),
          const SizedBox(height: 18),
          Text(
            widget.lesson.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          ...widget.lesson.points.asMap().entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      child: Text('${entry.key + 1}'),
                    ),
                    title: Text(entry.value),
                  ),
                ),
              ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _completed
                ? null
                : () {
                    setState(() => _completed = true);
                    Navigator.pop(context, true);
                  },
            icon: Icon(_completed ? Icons.check : Icons.school_outlined),
            label: Text(_completed ? 'LESSON COMPLETED' : 'MARK LESSON COMPLETE'),
          ),
        ],
      ),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
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
            Text(
              'Never approve an MFA prompt you did not initiate.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('Deny unexpected prompts, change the affected password, and review recent sign-ins.'),
          ],
        ),
      ),
    );
  }
}

class QuizCard extends StatefulWidget {
  const QuizCard({super.key});

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _selected;
  bool _checked = false;

  static const options = <String>[
    'Approve it quickly so the prompt goes away',
    'Deny it and review the account security',
    'Ignore every future MFA prompt',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You receive an MFA prompt you did not initiate. What should you do?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              options.length,
              (index) => RadioListTile<int>(
                value: index,
                groupValue: _selected,
                title: Text(options[index]),
                onChanged: (value) => setState(() {
                  _selected = value;
                  _checked = false;
                }),
              ),
            ),
            FilledButton(
              onPressed: _selected == null ? null : () => setState(() => _checked = true),
              child: const Text('CHECK ANSWER'),
            ),
            if (_checked) ...[
              const SizedBox(height: 12),
              Text(
                _selected == 1
                    ? 'Correct. Deny the prompt and investigate the account.'
                    : 'Not quite. Unexpected MFA prompts can indicate an attempted account takeover.',
                style: TextStyle(
                  color: _selected == 1 ? Colors.greenAccent : _red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
