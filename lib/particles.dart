import 'dart:math' as math;
import 'dart:ui' show Color;

import 'constants.dart';

/// جسيم واحد (دم، شرر، غبار).
class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
  }) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final Color color;

  /// نسبة العمر المتبقي من 0 إلى 1 (تستخدم للتلاشي في الرسم).
  double get fade => (life / maxLife).clamp(0.0, 1.0).toDouble();

  bool get dead => life <= 0;
}

/// نظام الجسيمات: إصابات، انفجارات، موت العمالقة.
class ParticleSystem {
  final math.Random _rnd = math.Random();
  final List<Particle> particles = <Particle>[];

  int get count => particles.length;

  /// إطلاق مجموعة جسيمات من نقطة معيّنة باتجاهات عشوائية.
  void emit(
    double x,
    double y, {
    required int count,
    required Color color,
    double speed = 120,
    double life = 0.5,
    double size = 3,
  }) {
    for (int i = 0; i < count; i++) {
      // لا نتجاوز الحد الأقصى للحفاظ على سلاسة اللعبة.
      if (particles.length >= GameConst.maxParticles) {
        particles.removeAt(0);
      }
      final double angle = _rnd.nextDouble() * math.pi * 2;
      final double v = speed * (0.35 + _rnd.nextDouble() * 0.65);
      particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * v,
        vy: math.sin(angle) * v,
        life: life * (0.6 + _rnd.nextDouble() * 0.4),
        size: size * (0.6 + _rnd.nextDouble() * 0.6),
        color: color,
      ));
    }
  }

  void update(double dt) {
    // احتكاك يبطئ الجسيمات تدريجياً.
    final double drag = math.max(0.0, 1 - 3.2 * dt);
    for (final Particle p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= drag;
      p.vy *= drag;
      p.life -= dt;
    }
    particles.removeWhere((Particle p) => p.dead);
  }

  void clear() {
    particles.clear();
  }
}
