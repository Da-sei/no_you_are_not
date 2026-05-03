import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _isUser ? 'YOU' : 'SYSTEM',
              style: GoogleFonts.bebasNeue(
                fontSize: 10,
                letterSpacing: 3,
                color: _isUser ? AppTheme.textSecondary : AppTheme.accent,
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
              decoration: BoxDecoration(
                color: _isUser ? AppTheme.surface : AppTheme.accent,
                border: Border(
                  left: !_isUser
                      ? const BorderSide(color: Colors.white24, width: 2)
                      : BorderSide.none,
                  right: _isUser
                      ? const BorderSide(color: AppTheme.border, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                message.content,
                style: AppTheme.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
