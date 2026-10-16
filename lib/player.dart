import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'constants.dart';

/// الجندي الذي يتحكم به اللاعب.
class Player {
  Player()
      : x = GameConst.wallCenterX,
        y = GameConst.wallCenterY + GameConst.wallRadius + 45,
        maxHealth = GameConst.playerBaseHealth,
        health = GameConst.playerBaseHealth;

  double x;
  double y;
  final double radius = GameConst.playerRadius;

  final double maxHealth;
  double health;

  /// اتجاه التصويب (يتجه تلقائياً نحو أقرب عملاق).
  double aimAngle = -math.pi / 2;

  /// مدة الحصانة بعد تلقي ضربة (بالثواني) حتى لا يموت فوراً.
  double invincible = 0;

  /// وميض أحمر عند الإصابة (للرسم).
  double hitFlash = 0;

  /// لحركة الأرجل في الرسم.
  double walkPhase = 0;
  bool moving = false;

  bool get isDead => health <= 0;

  double get fraction => (health / maxHealth).clamp(0.0, 1.0).toDouble();

  void update(double dt, Offset input) {
    if (invincible > 0) invincible -= dt;
    if (hitFlash > 0) hitFlash -= dt;

    moving = input.distance > 0.05;
    if (moving) {
      x += input.dx * GameConst.playerSpeed * dt;
      y += input.dy * GameConst.playerSpeed * dt;
      walkPhase += dt * 10;
    }
    _constrain();
  }

  /// يبقي اللاعب داخل العالم، وخارج الجدار، وقريباً من المدينة.
  void _constrain() {
    // حدود الشاشة.
    x = x.clamp(radius, GameConst.worldWidth - radius).toDouble();
    y = y.clamp(radius, GameConst.worldHeight - radius).toDouble();

    final double dx = x - GameConst.wallCenterX;
    final double dy = y - GameConst.wallCenterY;
    final double d = math.sqrt(dx * dx + dy * dy);
    if (d < 0.001) {
      y = GameConst.wallCenterY + GameConst.wallRadius + radius + 4;
      return;
    }

    final double minD = GameConst.wallRadius + radius + 4;
    final double maxD = GameConst.playerMaxDistance;
    double target = d;
    if (d < minD) target = minD;
    if (d > maxD) target = maxD;
    if (target != d) {
      x = GameConst.wallCenterX + dx / d * target;
      y = GameConst.wallCenterY + dy / d * target;
    }
  }

  void takeDamage(double amount) {
    if (amount <= 0 || isDead || invincible > 0) return;
    health -= amount;
    if (health < 0) health = 0;
    invincible = 1.0;
    hitFlash = 0.2;
  }

  void heal(double amount) {
    if (amount <= 0 || isDead) return;
    health += amount;
    if (health > maxHealth) health = maxHealth;
  }
}
