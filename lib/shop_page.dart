import 'package:flutter/material.dart';

import 'bullet.dart';
import 'save_service.dart';
import 'theme.dart';

/// المتجر: شراء الأسلحة وتحسين الضرر وسرعة الإطلاق وقوة الجدار.
class ShopPage extends StatelessWidget {
  const ShopPage({Key? key}) : super(key: key);

  static const int maxLevel = 10;

  static int damageCost(int level) => 150 + 100 * level;
  static int fireRateCost(int level) => 150 + 100 * level;
  static int wallCost(int level) => 200 + 150 * level;

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر والتطوير'),
        actions: <Widget>[
          AnimatedBuilder(
            animation: SaveService.instance,
            builder: (BuildContext context, Widget? _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.monetization_on,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${SaveService.instance.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: SaveService.instance,
          builder: (BuildContext context, Widget? _) {
            final SaveService s = SaveService.instance;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const _SectionTitle('الأسلحة'),
                for (final WeaponData w in WeaponData.all)
                  _weaponCard(context, s, w),
                const SizedBox(height: 12),
                const _SectionTitle('التحسينات'),
                _upgradeCard(
                  context,
                  icon: Icons.bolt,
                  title: 'قوة الضرر',
                  description: 'كل مستوى يزيد ضرر كل الأسلحة 20%',
                  level: s.damageLevel,
                  cost: damageCost(s.damageLevel),
                  coins: s.coins,
                  onBuy: () => s.upgradeDamage(damageCost(s.damageLevel)),
                ),
                _upgradeCard(
                  context,
                  icon: Icons.speed,
                  title: 'سرعة الإطلاق',
                  description: 'كل مستوى يزيد سرعة الإطلاق 12%',
                  level: s.fireRateLevel,
                  cost: fireRateCost(s.fireRateLevel),
                  coins: s.coins,
                  onBuy: () => s.upgradeFireRate(fireRateCost(s.fireRateLevel)),
                ),
                _upgradeCard(
                  context,
                  icon: Icons.shield,
                  title: 'تقوية الجدار',
                  description: 'كل مستوى يزيد صحة الجدار 25%',
                  level: s.wallLevel,
                  cost: wallCost(s.wallLevel),
                  coins: s.coins,
                  onBuy: () => s.upgradeWall(wallCost(s.wallLevel)),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------- بطاقة سلاح ----------------

  Widget _weaponCard(BuildContext context, SaveService s, WeaponData w) {
    final bool owned = s.ownsWeapon(w.type);
    final bool equipped = s.currentWeaponType == w.type;
    final bool canAfford = s.coins >= w.price;

    String buttonText;
    VoidCallback? onPressed;
    if (equipped) {
      buttonText = 'مُجهَّز';
      onPressed = null;
    } else if (owned) {
      buttonText = 'تجهيز';
      onPressed = () => s.equipWeapon(w.type);
    } else {
      buttonText = '${w.price}';
      onPressed = () {
        if (!canAfford) {
          _toast(context, 'العملات غير كافية');
          return;
        }
        if (s.buyWeapon(w.type, w.price)) {
          s.equipWeapon(w.type);
          _toast(context, 'تم شراء ${w.name}');
        }
      };
    }

    return _Card(
      highlight: equipped,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              owned ? Icons.gps_fixed : Icons.lock_outline,
              color: owned ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  w.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  w.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الضرر ${w.damage.round()}'
                  '${w.pellets > 1 ? ' ×${w.pellets}' : ''}'
                  ' • السرعة ${w.fireRate}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallButton(
            text: buttonText,
            showCoin: !owned,
            enabled: onPressed != null,
            dim: !owned && !canAfford,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  // ---------------- بطاقة تحسين ----------------

  Widget _upgradeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int level,
    required int cost,
    required int coins,
    required bool Function() onBuy,
  }) {
    final bool maxed = level >= maxLevel;
    final bool canAfford = coins >= cost;

    return _Card(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level / maxLevel,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المستوى $level / $maxLevel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallButton(
            text: maxed ? 'الأقصى' : '$cost',
            showCoin: !maxed,
            enabled: !maxed,
            dim: !maxed && !canAfford,
            onPressed: maxed
                ? null
                : () {
                    if (!canAfford) {
                      _toast(context, 'العملات غير كافية');
                      return;
                    }
                    onBuy();
                  },
          ),
        ],
      ),
    );
  }
}

// ======================================================
//                    عناصر مساعدة
// ======================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.highlight = false});

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.text,
    required this.onPressed,
    this.showCoin = false,
    this.enabled = true,
    this.dim = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool showCoin;
  final bool enabled;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final Color bg = !enabled
        ? AppColors.surfaceLight
        : (dim ? const Color(0xFF5E4F2A) : AppColors.primary);
    final Color fg = !enabled ? AppColors.textSecondary : Colors.black;

    return SizedBox(
      width: 84,
      height: 40,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(84, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (showCoin) ...<Widget>[
              const Icon(Icons.monetization_on, size: 14),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
