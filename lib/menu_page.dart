import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_page.dart';
import 'save_service.dart';
import 'shop_page.dart';
import 'theme.dart';

/// القائمة الرئيسية: العنوان، الأرقام القياسية، وأزرار اللعب والمتجر والإعدادات.
class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  void _openGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GamePage()),
    );
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopPage()),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('طريقة اللعب'),
          content: const SingleChildScrollView(
            child: Text(
              '• حرّك الجندي بالعصا على اليسار.\n'
              '• اضغط زر النار على اليمين، والتصويب تلقائي نحو أقرب عملاق.\n'
              '• لكل عملاق نقطة ضعف حمراء مضيئة على ظهره، وإصابتها تضاعف الضرر أربع مرات.\n'
              '• المدرّع تختفي نقطة ضعفه أحياناً، فانتظر لحظة كشفها.\n'
              '• لا تدع العمالقة يدمّرون الجدار، والتقط الصناديق لترميمه وعلاج جندي.\n'
              '• كل خمس موجات يظهر زعيم ضخم.\n'
              '• اكسب العملات واشترِ أسلحة وتحسينات من المتجر.',
              style: TextStyle(height: 1.6),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return AnimatedBuilder(
          animation: SaveService.instance,
          builder: (BuildContext context, Widget? _) {
            final SaveService s = SaveService.instance;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SwitchListTile(
                      value: s.soundOn,
                      onChanged: s.setSound,
                      title: const Text('الصوت'),
                      activeColor: AppColors.primary,
                    ),
                    SwitchListTile(
                      value: s.vibrationOn,
                      onChanged: s.setVibration,
                      title: const Text('الاهتزاز'),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmReset(ctx),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      label: const Text('مسح كل التقدم'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('مسح التقدم؟'),
          content: const Text(
              'ستُحذف العملات والأسلحة والتحسينات والأرقام القياسية، ولا يمكن التراجع.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await SaveService.instance.resetAll();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('مسح',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1A1512), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: SaveService.instance,
            builder: (BuildContext context, Widget? _) {
              final SaveService s = SaveService.instance;
              return Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Center(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(painter: _EmblemPainter()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'حرّاس الجدار',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'احمِ المدينة من العمالقة',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _StatTile(
                                icon: Icons.waves,
                                label: 'أعلى موجة',
                                value: '${s.bestWave}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.emoji_events,
                                label: 'أعلى نقاط',
                                value: '${s.bestScore}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.monetization_on,
                                label: 'العملات',
                                value: '${s.coins}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _openGame(context),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: const Text('ابدأ اللعب'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openShop(context),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('المتجر والتطوير'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showHowToPlay(context),
                                icon: const Icon(Icons.help_outline),
                                label: const Text('كيف ألعب'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showSettings(context),
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('الإعدادات'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// شعار اللعبة: جدار دائري ونقطة ضعف حمراء.
class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width * 0.38;
    final Paint p = Paint();

    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF3A362E);
    canvas.drawCircle(c, r, p);

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..color = AppColors.wall;
    canvas.drawCircle(c, r, p);

    p
      ..strokeWidth = 2
      ..color = AppColors.wallDark;
    for (int i = 0; i < 14; i++) {
      final double a = i * math.pi * 2 / 14;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r - size.width * 0.06),
        c + Offset(math.cos(a), math.sin(a)) * (r + size.width * 0.06),
        p,
      );
    }

    p
      ..style = PaintingStyle.fill
      ..color = AppColors.weakSpot.withAlpha(80);
    canvas.drawCircle(c, size.width * 0.17, p);
    p.color = AppColors.weakSpot;
    canvas.drawCircle(c, size.width * 0.08, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
