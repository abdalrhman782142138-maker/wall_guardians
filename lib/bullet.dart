import 'dart:math' as math;

import 'constants.dart';

/// بيانات السلاح: تُستخدم في المحرك والمتجر.
class WeaponData {
  const WeaponData({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.damage,
    required this.fireRate,
    required this.pellets,
    required this.spread,
    required this.bulletSpeed,
    required this.explosionRadius,
    required this.recoilShake,
  });

  final WeaponType type;
  final String name;
  final String description;

  /// السعر بالعملات (المسدس مجاني).
  final int price;

  /// ضرر الرصاصة الواحدة.
  final double damage;

  /// عدد الطلقات في الثانية.
  final double fireRate;

  /// عدد الرصاصات في الطلقة الواحدة (الشوزن أكثر من واحدة).
  final int pellets;

  /// تشتت الرصاص بالراديان.
  final double spread;

  final double bulletSpeed;

  /// نصف قطر الانفجار (0 = بدون انفجار).
  final double explosionRadius;

  /// قوة اهتزاز الكاميرا عند كل طلقة.
  final double recoilShake;

  static const WeaponData pistol = WeaponData(
    type: WeaponType.pistol,
    name: 'مسدس',
    description: 'دقيق وموثوق، مناسب للبداية',
    price: 0,
    damage: 12,
    fireRate: 4,
    pellets: 1,
    spread: 0.05,
    bulletSpeed: GameConst.bulletSpeed,
    explosionRadius: 0,
    recoilShake: 0.3,
  );

  static const WeaponData rifle = WeaponData(
    type: WeaponType.rifle,
    name: 'بندقية',
    description: 'إطلاق سريع ومستمر',
    price: 400,
    damage: 9,
    fireRate: 9,
    pellets: 1,
    spread: 0.09,
    bulletSpeed: 600,
    explosionRadius: 0,
    recoilShake: 0.4,
  );

  static const WeaponData shotgun = WeaponData(
    type: WeaponType.shotgun,
    name: 'شوزن',
    description: 'قوي جداً على المدى القريب',
    price: 900,
    damage: 8,
    fireRate: 1.4,
    pellets: 6,
    spread: 0.5,
    bulletSpeed: 480,
    explosionRadius: 0,
    recoilShake: 2.2,
  );

  static const WeaponData launcher = WeaponData(
    type: WeaponType.launcher,
    name: 'قاذفة',
    description: 'انفجار يضرب مجموعة عمالقة',
    price: 1800,
    damage: 45,
    fireRate: 0.9,
    pellets: 1,
    spread: 0.02,
    bulletSpeed: 340,
    explosionRadius: 55,
    recoilShake: 3.5,
  );

  static const List<WeaponData> all = <WeaponData>[
    pistol,
    rifle,
    shotgun,
    launcher,
  ];

  static WeaponData of(WeaponType type) => all[type.index];
}

/// رصاصة أو قذيفة.
class Bullet {
  Bullet({
    required this.x,
    required this.y,
    required double angle,
    required double speed,
    required this.damage,
    this.explosionRadius = 0,
  })  : vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = explosionRadius > 0
            ? GameConst.bulletRadius * 2
            : GameConst.bulletRadius,
        life = GameConst.bulletLife,
        prevX = x,
        prevY = y;

  double x;
  double y;
  final double vx;
  final double vy;
  final double damage;
  final double explosionRadius;
  final double radius;
  double life;
  bool dead = false;

  /// موضع سابق لرسم أثر الرصاصة.
  double prevX;
  double prevY;

  bool get isExplosive => explosionRadius > 0;

  void update(double dt) {
    prevX = x;
    prevY = y;
    x += vx * dt;
    y += vy * dt;
    life -= dt;
    if (life <= 0) dead = true;
  }
}
