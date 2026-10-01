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
      durationMinutes: 4,
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
      durationMinutes: 5,
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
      durationMinutes: 4,
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
      durationMinutes: 4,
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
          (lesson) {
            final complete = _completed.contains(lesson.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(lesson.icon, color: _red),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.summary),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${lesson.durationMinutes} min',
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            complete ? 'COMPLETED' : 'NOT COMPLETED',
                            style: TextStyle(
                              color: complete ? Colors.greenAccent : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: complete
                      ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _openLesson(lesson),
                ),
              ),
            );
          },
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
    required this.durationMinutes,
    required this.points,
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final int durationMinutes;
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
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text('${widget.lesson.durationMinutes} min'),
              ),
              if (_completed)
                const Chip(
                  avatar: Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                  label: Text('Completed'),
                ),
            ],
          ),
          const SizedBox(height: 12),
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

  static const options = <String>[
    'Approve it quickly so the prompt goes away',
    'Deny it and review the account security',
    'Ignore every future MFA prompt',
  ];

  String get _feedback {
    switch (_selected) {
      case 0:
        return 'That is unsafe. Approving an unexpected prompt can authorize an attacker. This technique is often called MFA fatigue or push bombing.';
      case 1:
        return 'Correct. Deny the unexpected prompt, then review recent sign-ins, active sessions, password security, and MFA settings.';
      case 2:
        return 'Not quite. Ignoring every future prompt can hide legitimate activity. Deny unexpected prompts and investigate why they appeared.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final correct = _selected == 1;
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
              (index) {
                final selected = _selected == index;
                return Card(
                  color: selected ? _red.withValues(alpha: .12) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: selected ? _red : Colors.transparent),
                  ),
                  child: RadioListTile<int>(
                    value: index,
                    groupValue: _selected,
                    activeColor: _red,
                    title: Text(options[index]),
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                );
              },
            ),
            if (_selected != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (correct ? Colors.greenAccent : _red).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (correct ? Colors.greenAccent : _red).withValues(alpha: .55),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      correct ? Icons.check_circle_outline : Icons.info_outline,
                      color: correct ? Colors.greenAccent : _red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedback,
                        style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
