import 'dart:math' as math;

import 'constants.dart';

/// نوع المكافأة التي يسقطها العملاق عند موته.
enum PickupType {
  repair, // ترميم الجدار
  heal, // علاج اللاعب
}

/// مكافأة على الأرض يلتقطها اللاعب بالاقتراب منها.
class Pickup {
  Pickup({
    required this.type,
    required this.x,
    required this.y,
  }) : life = GameConst.pickupLife;

  final PickupType type;
  final double x;
  final double y;
  final double radius = 10;

  double life;
  double age = 0;
  bool dead = false;

  /// تومض المكافأة في آخر ثلاث ثوانٍ قبل أن تختفي.
  bool get blinking => life < 3;

  /// نسبة العمر المتبقي من 0 إلى 1.
  double get fraction =>
      (life / GameConst.pickupLife).clamp(0.0, 1.0).toDouble();

  /// حركة طفو بسيطة تستخدم في الرسم.
  double get bob => math.sin(age * 4) * 2.5;

  void update(double dt) {
    age += dt;
    life -= dt;
    if (life <= 0) dead = true;
  }
}
