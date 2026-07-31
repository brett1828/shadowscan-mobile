import 'package:flutter/material.dart';

void main() {
  runApp(const ShadowScanApp());
}

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
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    _HomePage(),
    _PlaceholderPage(
      icon: Icons.public,
      title: 'Exposure',
      message: 'Breach monitoring and verified identities will live here.',
    ),
    _PlaceholderPage(
      icon: Icons.wifi_tethering,
      title: 'Wi-Fi Safety',
      message: 'Current-network checks and safety guidance will live here.',
    ),
    _PlaceholderPage(
      icon: Icons.school_outlined,
      title: 'Learn',
      message: 'Daily tips, awareness lessons, and micro-quizzes will live here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_moon_outlined),
            SizedBox(width: 10),
            Text('ShadowScan'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_none),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: const [
        _WelcomeHeader(),
        SizedBox(height: 16),
        _ScoreCard(),
        SizedBox(height: 16),
        _SectionTitle(title: 'Priority actions', actionLabel: 'View all'),
        SizedBox(height: 10),
        _PriorityAction(
          icon: Icons.phonelink_lock,
          title: 'Enable MFA on your primary email',
          severity: 'High priority',
        ),
        SizedBox(height: 10),
        _PriorityAction(
          icon: Icons.password,
          title: 'Replace a reused password',
          severity: 'High priority',
        ),
        SizedBox(height: 16),
        _DailyTipCard(),
        SizedBox(height: 16),
        _SectionTitle(title: 'Latest activity'),
        SizedBox(height: 10),
        _ActivityCard(),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good afternoon, Brett', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Here is your current digital-risk posture.'),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard();

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
                    value: 0.72,
                    strokeWidth: 9,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('72', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
                      Text('/100', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shadow Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Moderate risk', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 7),
                  Text('Resolve two high-priority findings to strengthen your posture.'),
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
  const _SectionTitle({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        if (actionLabel != null) Text(actionLabel!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
}

class _PriorityAction extends StatelessWidget {
  const _PriorityAction({required this.icon, required this.title, required this.severity});

  final IconData icon;
  final String title;
  final String severity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(severity),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: primary),
                const SizedBox(width: 8),
                const Text('Cyber Tip of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Never approve an MFA prompt you did not initiate.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Repeated prompts may be an MFA-fatigue attack. Deny the request, change your password, and review recent sign-ins.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Account security')),
                Chip(label: Text('Easy action')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.mark_email_read_outlined)),
        title: Text('No new exposure alerts'),
        subtitle: Text('Monitoring status will appear after you verify an email address.'),
      ),
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
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
