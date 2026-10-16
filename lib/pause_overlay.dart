import 'package:flutter/material.dart';

import 'theme.dart';

/// نافذة الإيقاف المؤقت. تغطي الشاشة وتمنع اللمس عن اللعبة.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    Key? key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  }) : super(key: key);

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC000000),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'إيقاف مؤقت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('متابعة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: const Text('إعادة الجولة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('القائمة الرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
