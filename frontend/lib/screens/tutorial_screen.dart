import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/typewriter_text.dart';

class TutorialScreen extends StatefulWidget {
  final bool forcedFlow;

  const TutorialScreen({super.key, this.forcedFlow = true});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    if (widget.forcedFlow) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_seen', true);
      if (mounted) context.go('/missions');
    } else {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.forcedFlow
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(),
              ),
            ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _VerdictPage(onNext: _nextPage),
          _MissionPage(onNext: _nextPage),
          _InterrogationPage(onNext: _nextPage),
          _ThoughtLogPage(onComplete: _complete),
        ],
      ),
    );
  }
}

// ── Page 0: THE VERDICT ──────────────────────────────────────────────────────

class _VerdictPage extends StatefulWidget {
  final VoidCallback onNext;

  const _VerdictPage({required this.onNext});

  @override
  State<_VerdictPage> createState() => _VerdictPageState();
}

class _VerdictPageState extends State<_VerdictPage>
    with SingleTickerProviderStateMixin {
  bool _showLine2 = false;
  bool _showUnderline = false;
  bool _showSubtext = false;
  bool _showCta = false;
  late final AnimationController _underlineCtrl;
  late final Animation<double> _underlineAnim;

  @override
  void initState() {
    super.initState();
    _underlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _underlineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _underlineCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _underlineCtrl.dispose();
    super.dispose();
  }

  void _onLine1Done() {
    if (mounted) setState(() => _showLine2 = true);
  }

  Future<void> _onLine2Done() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showUnderline = true);
    _underlineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showSubtext = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showCta = true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypewriterText(
              text: 'NO,',
              style: AppTheme.display,
              charDuration: const Duration(milliseconds: 80),
              onComplete: _onLine1Done,
            ),
            if (_showLine2)
              TypewriterText(
                text: 'YOU ARE NOT.',
                style: AppTheme.display.copyWith(color: AppTheme.accent),
                charDuration: const Duration(milliseconds: 60),
                onComplete: _onLine2Done,
              ),
            const SizedBox(height: 8),
            _showUnderline
                ? AnimatedBuilder(
                    animation: _underlineAnim,
                    builder: (_, __) => FractionallySizedBox(
                      widthFactor: _underlineAnim.value,
                      alignment: Alignment.centerLeft,
                      child: Container(height: 2, color: AppTheme.accent),
                    ),
                  )
                : const SizedBox(height: 2),
            const SizedBox(height: 32),
            AnimatedOpacity(
              opacity: _showSubtext ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Text(
                '甘えと言い訳を、論理で封じ込む。',
                style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 48),
            AnimatedOpacity(
              opacity: _showCta ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: AbsorbPointer(
                absorbing: !_showCta,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    child: Text(
                      'UNDERSTOOD',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 16,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: SET YOUR MISSION ─────────────────────────────────────────────────

class _MissionPage extends StatefulWidget {
  final VoidCallback onNext;

  const _MissionPage({required this.onNext});

  @override
  State<_MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<_MissionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: _MockDashboardHeader(pulseAnim: _pulseAnim),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NO ACTIVE\nMISSIONS.', style: AppTheme.display),
                const SizedBox(height: 16),
                Text(
                  "You have no goal to avoid.\nThat's convenient, isn't it?",
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        ),
        _BottomPanel(
          step: 'STEP 1 / SET YOUR MISSION',
          description: '目標・期限・動機を登録。一度コミットしたら編集不可。',
          ctaLabel: 'NEXT →',
          onCta: widget.onNext,
        ),
      ],
    );
  }
}

class _MockDashboardHeader extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _MockDashboardHeader({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NO,', style: AppTheme.display),
                Text(
                  'YOU ARE NOT.',
                  style: AppTheme.display.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: pulseAnim,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accent, width: 2),
              ),
              child: const Icon(Icons.add, color: AppTheme.accent, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: THE INTERROGATION ────────────────────────────────────────────────

class _InterrogationPage extends StatefulWidget {
  final VoidCallback onNext;

  const _InterrogationPage({required this.onNext});

  @override
  State<_InterrogationPage> createState() => _InterrogationPageState();
}

class _InterrogationPageState extends State<_InterrogationPage> {
  bool _showAi1 = false;
  bool _showTyping1 = false;
  bool _showUser = false;
  bool _showTyping2 = false;
  bool _showAi2 = false;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showAi1 = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showTyping1 = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _showTyping1 = false;
      _showUser = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _showTyping2 = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _showTyping2 = false;
      _showAi2 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Text('INTERROGATION', style: AppTheme.heading),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_showAi1) _MockAiBubble(text: 'なぜ、今日できなかったのか？'),
              if (_showTyping1) const _MockTypingBubble(),
              if (_showUser) _MockUserBubble(text: '疲れていたから…'),
              if (_showTyping2) const _MockTypingBubble(),
              if (_showAi2)
                _MockAiBubble(text: '疲労は行動しない\n理由にはなりません。'),
            ],
          ),
        ),
        _BottomPanel(
          step: 'STEP 2 / THE INTERROGATION',
          description: 'AIが論理的矛盾を突く。言い訳は通用しない。',
          ctaLabel: 'NEXT →',
          onCta: widget.onNext,
        ),
      ],
    );
  }
}

class _MockAiBubble extends StatelessWidget {
  final String text;

  const _MockAiBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'SYSTEM',
              style: GoogleFonts.bebasNeue(
                fontSize: 10,
                letterSpacing: 3,
                color: AppTheme.accent,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                border: Border(
                  left: BorderSide(color: Colors.white24, width: 2),
                ),
              ),
              child: Text(
                text,
                style: AppTheme.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockUserBubble extends StatelessWidget {
  final String text;

  const _MockUserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'YOU',
              style: GoogleFonts.bebasNeue(
                fontSize: 10,
                letterSpacing: 3,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  right: BorderSide(color: AppTheme.border, width: 2),
                ),
              ),
              child: Text(
                text,
                style: AppTheme.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTypingBubble extends StatefulWidget {
  const _MockTypingBubble();

  @override
  State<_MockTypingBubble> createState() => _MockTypingBubbleState();
}

class _MockTypingBubbleState extends State<_MockTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _dots(double v) {
    if (v < 0.33) return '·';
    if (v < 0.66) return '· ·';
    return '· · ·';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'SYSTEM',
              style: GoogleFonts.bebasNeue(
                fontSize: 10,
                letterSpacing: 3,
                color: AppTheme.accent,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              border: Border(
                left: BorderSide(color: Colors.white24, width: 2),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Text(
                _dots(_ctrl.value),
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: YOUR THOUGHT LOG ─────────────────────────────────────────────────

class _ThoughtLogPage extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _ThoughtLogPage({required this.onComplete});

  @override
  State<_ThoughtLogPage> createState() => _ThoughtLogPageState();
}

class _ThoughtLogPageState extends State<_ThoughtLogPage>
    with TickerProviderStateMixin {
  late final List<AnimationController> _stampCtrls;
  late final List<Animation<double>> _stampAnims;
  bool _completing = false;

  static const _entries = [
    ('毎日筋トレをする', '体が疲れていたから'),
    ('読書を週3冊こなす', '時間がなかったから'),
    ('副業で月5万稼ぐ', 'モチベーションが出なかったから'),
  ];

  @override
  void initState() {
    super.initState();
    _stampCtrls = List.generate(
      _entries.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _stampAnims = _stampCtrls.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 70),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();
    _animateStamps();
  }

  Future<void> _animateStamps() async {
    for (var i = 0; i < _entries.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _stampCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _stampCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Text('THOUGHT LOG', style: AppTheme.heading),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => Stack(
              children: [
                _MockLogCard(
                  goal: _entries[i].$1,
                  excuse: _entries[i].$2,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _stampAnims[i],
                        builder: (_, __) => Transform.scale(
                          scale: _stampAnims[i].value,
                          child: Transform.rotate(
                            angle: -0.21,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.accent,
                                  width: 3,
                                ),
                              ),
                              child: Text(
                                'DEFEATED',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 28,
                                  color: AppTheme.accent,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomPanel(
          step: 'STEP 3 / YOUR THOUGHT LOG',
          description: '論破された言い訳が蓄積される。思考の癖を直視せよ。',
          ctaLabel: 'BEGIN MISSION',
          loading: _completing,
          onCta: _completing
              ? null
              : () async {
                  setState(() => _completing = true);
                  await widget.onComplete();
                },
        ),
      ],
    );
  }
}

class _MockLogCard extends StatelessWidget {
  final String goal;
  final String excuse;

  const _MockLogCard({required this.goal, required this.excuse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal, style: AppTheme.body),
          const SizedBox(height: 4),
          Text(excuse, style: AppTheme.caption),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final String step;
  final String description;
  final String ctaLabel;
  final VoidCallback? onCta;
  final bool loading;

  const _BottomPanel({
    required this.step,
    required this.description,
    required this.ctaLabel,
    this.onCta,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: AppTheme.label.copyWith(color: AppTheme.accent),
          ),
          const SizedBox(height: 8),
          Text(description, style: AppTheme.caption),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCta,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : Text(
                      ctaLabel,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 16,
                        letterSpacing: 3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
