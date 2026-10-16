import 'package:flutter/material.dart';

import 'theme.dart';

/// نافذة نهاية الجولة: النتيجة والعملات المكتسبة وأزرار الإعادة والمتجر.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    Key? key,
    required this.wave,
    required this.score,
    required this.coins,
    required this.kills,
    required this.newRecord,
    required this.newWaveRecord,
    required this.onRestart,
    required this.onShop,
    required this.onExit,
  }) : super(key: key);

  final int wave;
  final int score;
  final int coins;
  final int kills;
  final bool newRecord;
  final bool newWaveRecord;
  final VoidCallback onRestart;
  final VoidCallback onShop;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xDD000000),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.danger, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'سقط الجدار',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'اجتاح العمالقة المدينة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                if (newRecord || newWaveRecord) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x33C9A24B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.emoji_events,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'رقم قياسي جديد!',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _Row(label: 'الموجة', value: '$wave'),
                _Row(label: 'النقاط', value: '$score'),
                _Row(label: 'العمالقة المقتولة', value: '$kills'),
                _Row(
                  label: 'العملات المكتسبة',
                  value: '+$coins',
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: const Text('لعب مرة أخرى'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onShop,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('المتجر والتطوير'),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
