import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
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

  String _dots(double value) {
    if (value < 0.33) return '·';
    if (value < 0.66) return '· ·';
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
              builder: (_, child) => Text(
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
