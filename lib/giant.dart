import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'constants.dart';

/// العملاق: يزحف نحو الجدار ويهاجمه.
/// نقطة ضعفه خلف الجسم (مثل مؤخرة العنق)، وإصابتها تضاعف الضرر.
class Giant {
  Giant({
    required this.type,
    required this.x,
    required this.y,
    required int wave,
  }) {
    final _Stats s = _Stats.of(type);
    final double growth = 1 + GameConst.healthGrowthPerWave * (wave - 1);

    radius = s.radius;
    maxHealth = s.health * growth;
    health = maxHealth;
    speed = s.speed * (1 + 0.015 * (wave - 1)).clamp(1.0, 1.6).toDouble();
    wallDamage = s.wallDamage;
    contactDamage = s.contactDamage;
    bodyDamageFactor = s.bodyFactor;
    reward = (s.reward * (1 + 0.05 * (wave - 1))).round();

    angle = math.atan2(GameConst.wallCenterY - y, GameConst.wallCenterX - x);
    // كل عملاق يبدأ بمرحلة مختلفة حتى لا تتزامن الحركات.
    _phase = math.Random().nextDouble() * 10;
    _weakTimer = math.Random().nextDouble() * 2;
  }

  final GiantType type;
  double x;
  double y;

  late final double radius;
  late final double maxHealth;
  late double health;
  late final double speed;
  late final double wallDamage;
  late final double contactDamage;
  late final double bodyDamageFactor;
  late final int reward;

  /// اتجاه النظر (نحو الجدار).
  double angle = 0;

  bool dead = false;

  /// هل يهاجم الجدار الآن.
  bool attacking = false;

  /// وميض عند الإصابة للرسم.
  double hitFlash = 0;

  double _phase = 0;
  double _weakTimer = 0;
  bool _weakOpen = true;

  /// مرحلة المشي (للرسم).
  double get walkPhase => _phase;

  double get fraction => (health / maxHealth).clamp(0.0, 1.0).toDouble();

  bool get isBoss => type == GiantType.boss;

  // ---------------- نقطة الضعف ----------------

  /// المدرّع تظهر نقطة ضعفه في فترات فقط، والبقية دائماً مكشوفة.
  bool get weakVulnerable => type != GiantType.armored || _weakOpen;

  double get weakSpotRadius => radius * GameConst.weakSpotRatio;

  /// مكان نقطة الضعف: خلف الجسم بعكس اتجاه النظر.
  Offset get weakSpotPos => Offset(
        x - math.cos(angle) * radius * 0.75,
        y - math.sin(angle) * radius * 0.75,
      );

  // ---------------- التحديث ----------------

  void update(double dt) {
    _phase += dt * (speed / 12 + 2);
    if (hitFlash > 0) hitFlash -= dt;

    if (type == GiantType.armored) {
      _weakTimer -= dt;
      if (_weakTimer <= 0) {
        _weakOpen = !_weakOpen;
        // تنكشف 1.3 ثانية وتختفي 1.9 ثانية.
        _weakTimer = _weakOpen ? 1.3 : 1.9;
      }
    }

    final double dx = GameConst.wallCenterX - x;
    final double dy = GameConst.wallCenterY - y;
    final double d = math.sqrt(dx * dx + dy * dy);
    angle = math.atan2(dy, dx);

    final double stopAt = GameConst.wallRadius + radius * 0.7;
    if (d <= stopAt) {
      attacking = true;
      return;
    }
    attacking = false;

    final double step = speed * dt;
    x += dx / d * step;
    y += dy / d * step;
  }

  void takeDamage(double amount) {
    if (amount <= 0 || dead) return;
    health -= amount;
    hitFlash = 0.1;
  }

  /// يمنع العملاق من دخول الجدار عندما يدفعه غيره.
  void clampOutsideWall() {
    final double dx = x - GameConst.wallCenterX;
    final double dy = y - GameConst.wallCenterY;
    final double d = math.sqrt(dx * dx + dy * dy);
    final double minD = GameConst.wallRadius + radius * 0.6;
    if (d < minD && d > 0.001) {
      x = GameConst.wallCenterX + dx / d * minD;
      y = GameConst.wallCenterY + dy / d * minD;
    }
  }
}

/// أرقام كل نوع من العمالقة.
class _Stats {
  const _Stats({
    required this.radius,
    required this.health,
    required this.speed,
    required this.wallDamage,
    required this.contactDamage,
    required this.bodyFactor,
    required this.reward,
  });

  final double radius;
  final double health;
  final double speed;
  final double wallDamage; // ضرر في الثانية على الجدار
  final double contactDamage; // ضرر عند لمس اللاعب
  final double bodyFactor; // نسبة الضرر عند إصابة الجسم
  final int reward;

  static const _Stats crawler = _Stats(
    radius: 16,
    health: 40,
    speed: 32,
    wallDamage: 8,
    contactDamage: 8,
    bodyFactor: 1,
    reward: 10,
  );

  static const _Stats runner = _Stats(
    radius: 12,
    health: 25,
    speed: 80,
    wallDamage: 6,
    contactDamage: 6,
    bodyFactor: 1,
    reward: 14,
  );

  static const _Stats armored = _Stats(
    radius: 22,
    health: 160,
    speed: 26,
    wallDamage: 20,
    contactDamage: 15,
    bodyFactor: 0.25,
    reward: 40,
  );

  static const _Stats boss = _Stats(
    radius: 42,
    health: 1200,
    speed: 20,
    wallDamage: 60,
    contactDamage: 30,
    bodyFactor: 0.5,
    reward: 250,
  );

  static _Stats of(GiantType type) {
    switch (type) {
      case GiantType.crawler:
        return crawler;
      case GiantType.runner:
        return runner;
      case GiantType.armored:
        return armored;
      case GiantType.boss:
        return boss;
    }
  }
}
