import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'bullet.dart';
import 'constants.dart';
import 'game_engine.dart';
import 'giant.dart';
import 'giant_painter.dart';
import 'particles.dart';
import 'pickup.dart';
import 'player.dart';
import 'theme.dart';
import 'wall.dart';

/// يرسم العالم كله بالكود. العالم المنطقي 400×800 ويُكبَّر ليناسب أي شاشة.
class GamePainter extends CustomPainter {
  GamePainter(this.engine) : super(repaint: engine);

  final GameEngine engine;
  final Paint _p = Paint();

  // نقاط أرضية ثابتة (حصى وتراب) تتولد مرة واحدة.
  static final List<Offset> _dots = _makeDots();
  static List<Offset> _makeDots() {
    final math.Random r = math.Random(7);
    return List<Offset>.generate(
      110,
      (_) => Offset(
        r.nextDouble() * GameConst.worldWidth,
        r.nextDouble() * GameConst.worldHeight,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // لون الخلفية يملأ كامل الشاشة حتى مع الحواف الفارغة.
    _p
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, _p);

    final double scale = math.min(
      size.width / GameConst.worldWidth,
      size.height / GameConst.worldHeight,
    );
    final double ox = (size.width - GameConst.worldWidth * scale) / 2;
    final double oy = (size.height - GameConst.worldHeight * scale) / 2;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(
        0, 0, GameConst.worldWidth, GameConst.worldHeight));

    final Offset sh = engine.shake.offset;
    canvas.translate(sh.dx, sh.dy);

    _drawGround(canvas);
    _drawWall(canvas, engine.wall);
    for (final Pickup p in engine.pickups) {
      _drawPickup(canvas, p);
    }
    for (final Giant g in engine.giants) {
      GiantPainter.paint(canvas, g, engine.time);
    }
    for (final Bullet b in engine.bullets) {
      _drawBullet(canvas, b);
    }
    _drawPlayer(canvas, engine.player);
    _drawParticles(canvas);

    canvas.restore();

    _drawScreenEffects(canvas, size);
  }

  // ======================================================
  //                        الأرض
  // ======================================================

  void _drawGround(Canvas canvas) {
    _p
      ..style = PaintingStyle.fill
      ..color = AppColors.ground;
    canvas.drawRect(
      const Rect.fromLTWH(-30, -30, GameConst.worldWidth + 60,
          GameConst.worldHeight + 60),
      _p,
    );

    _p.color = const Color(0xFF353329);
    for (final Offset d in _dots) {
      canvas.drawCircle(d, 2.2, _p);
    }
    _p.color = const Color(0xFF211F1B);
    for (int i = 0; i < _dots.length; i += 3) {
      canvas.drawCircle(_dots[i] + const Offset(6, 4), 1.2, _p);
    }
  }

  // ======================================================
  //                        الجدار
  // ======================================================

  void _drawWall(Canvas canvas, Wall wall) {
    final Offset c = Offset(wall.x, wall.y);
    final double r = wall.radius;

    // ظل الجدار.
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0x66000000);
    canvas.drawCircle(c + const Offset(4, 6), r + 12, _p);

    // داخل المدينة.
    _p.color = const Color(0xFF3A362E);
    canvas.drawCircle(c, r - 4, _p);
    _drawHouses(canvas, c, r);

    // حلقة الجدار.
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = AppColors.wall;
    canvas.drawCircle(c, r, _p);

    _p
      ..strokeWidth = 3
      ..color = AppColors.wallDark;
    canvas.drawCircle(c, r + 8, _p);
    canvas.drawCircle(c, r - 8, _p);

    // فواصل الحجارة.
    _p
      ..strokeWidth = 2
      ..color = AppColors.wallDark;
    const int segments = 18;
    for (int i = 0; i < segments; i++) {
      final double a = i * math.pi * 2 / segments;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r - 8),
        c + Offset(math.cos(a), math.sin(a)) * (r + 8),
        _p,
      );
    }

    // تشققات عند تضرر الجدار.
    final double f = wall.fraction;
    if (f < 0.75) {
      _p
        ..strokeWidth = 2.5
        ..color = const Color(0xFF1C1A16);
      final int cracks = f < 0.25 ? 8 : (f < 0.5 ? 5 : 3);
      for (int i = 0; i < cracks; i++) {
        final double a = i * math.pi * 2 / cracks + 0.4;
        final Offset p1 = c + Offset(math.cos(a), math.sin(a)) * (r - 7);
        final Offset p2 =
            c + Offset(math.cos(a + 0.12), math.sin(a + 0.12)) * (r + 1);
        final Offset p3 =
            c + Offset(math.cos(a - 0.06), math.sin(a - 0.06)) * (r + 8);
        canvas.drawLine(p1, p2, _p);
        canvas.drawLine(p2, p3, _p);
      }
    }

    // وميض أحمر عند الضرب.
    if (wall.hitFlash > 0) {
      _p
        ..strokeWidth = 18
        ..color = AppColors.danger.withAlpha((wall.hitFlash / 0.15 * 110).round());
      canvas.drawCircle(c, r, _p);
    }
  }

  void _drawHouses(Canvas canvas, Offset c, double r) {
    _p.style = PaintingStyle.fill;
    const List<List<double>> houses = <List<double>>[
      <double>[-26, -22, 18, 14],
      <double>[6, -30, 20, 16],
      <double>[-12, 4, 24, 16],
      <double>[22, 8, 16, 14],
      <double>[-38, 12, 14, 12],
    ];
    for (final List<double> h in houses) {
      _p.color = const Color(0xFF5A4B3C);
      canvas.drawRect(Rect.fromLTWH(c.dx + h[0], c.dy + h[1], h[2], h[3]), _p);
      _p.color = const Color(0xFF7A3B2E);
      canvas.drawRect(
          Rect.fromLTWH(c.dx + h[0], c.dy + h[1], h[2], h[3] * 0.45), _p);
    }
  }

  // ======================================================
  //                       اللاعب
  // ======================================================

  void _drawPlayer(Canvas canvas, Player pl) {
    // وميض أثناء الحصانة.
    if (pl.invincible > 0 && ((engine.time * 14).floor() % 2 == 0)) return;

    // الظل.
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0x55000000);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pl.x + 2, pl.y + 4),
          width: pl.radius * 2.2,
          height: pl.radius * 2.0),
      _p,
    );

    canvas.save();
    canvas.translate(pl.x, pl.y);
    canvas.rotate(pl.aimAngle);

    final double r = pl.radius;

    // السلاح.
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2B2B2B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r * 0.4, -r * 0.22, r * 1.5, r * 0.44),
        Radius.circular(2),
      ),
      _p,
    );

    // الجسم.
    _p.color = pl.hitFlash > 0 ? const Color(0xFFE57373) : const Color(0xFF4F6B4A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.3, height: r * 2.0),
      _p,
    );

    // الذراع الممسكة بالسلاح.
    _p.color = const Color(0xFF3E5439);
    canvas.drawCircle(Offset(r * 0.55, r * 0.3), r * 0.28, _p);

    // الرأس.
    _p.color = const Color(0xFFD9B79A);
    canvas.drawCircle(Offset(r * 0.05, 0), r * 0.5, _p);
    _p.color = const Color(0xFF3B3A36);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(r * 0.05, 0), radius: r * 0.5),
      math.pi * 0.55,
      math.pi * 0.9,
      true,
      _p,
    );

    // وميض فوهة السلاح.
    if (engine.muzzleFlash > 0) {
      _p.color = const Color(0xFFFFE08A);
      canvas.drawCircle(Offset(r * 2.0, 0), r * 0.55, _p);
      _p.color = Colors.white;
      canvas.drawCircle(Offset(r * 2.0, 0), r * 0.25, _p);
    }

    canvas.restore();
  }

  // ======================================================
  //                الرصاص والمكافآت والجسيمات
  // ======================================================

  void _drawBullet(Canvas canvas, Bullet b) {
    if (b.isExplosive) {
      _p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF9800);
      canvas.drawCircle(Offset(b.x, b.y), b.radius, _p);
      _p.color = const Color(0xFFFFE082);
      canvas.drawCircle(Offset(b.x, b.y), b.radius * 0.5, _p);
      return;
    }
    _p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = b.radius * 1.2
      ..color = AppColors.bullet;
    canvas.drawLine(Offset(b.prevX, b.prevY), Offset(b.x, b.y), _p);
    _p.strokeCap = StrokeCap.butt;
  }

  void _drawPickup(Canvas canvas, Pickup pk) {
    if (pk.blinking && ((pk.age * 8).floor() % 2 == 0)) return;

    final Offset c = Offset(pk.x, pk.y + pk.bob);
    final bool heal = pk.type == PickupType.heal;
    final Color color = heal ? AppColors.success : AppColors.primary;

    _p
      ..style = PaintingStyle.fill
      ..color = color.withAlpha(60);
    canvas.drawCircle(c, pk.radius * 1.8, _p);
    _p.color = const Color(0xFF1A1C23);
    canvas.drawCircle(c, pk.radius, _p);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawCircle(c, pk.radius, _p);

    if (heal) {
      // علامة +
      _p
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c + const Offset(-5, 0), c + const Offset(5, 0), _p);
      canvas.drawLine(c + const Offset(0, -5), c + const Offset(0, 5), _p);
      _p.strokeCap = StrokeCap.butt;
    } else {
      // حجارة ترميم.
      _p.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 7), _p);
    }
  }

  void _drawParticles(Canvas canvas) {
    _p.style = PaintingStyle.fill;
    for (final Particle pt in engine.particles.particles) {
      _p.color = pt.color.withAlpha((pt.fade * 255).round());
      canvas.drawCircle(Offset(pt.x, pt.y), pt.size * (0.5 + 0.5 * pt.fade), _p);
    }
  }

  // ======================================================
  //                   تأثيرات الشاشة كاملة
  // ======================================================

  void _drawScreenEffects(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // تعتيم الحواف.
    _p
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        radius: 0.95,
        colors: <Color>[Color(0x00000000), Color(0x99000000)],
        stops: <double>[0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, _p);
    _p.shader = null;

    // وميض أحمر عند إصابة اللاعب.
    final double flash = engine.player.hitFlash;
    if (flash > 0) {
      _p.color = AppColors.danger.withAlpha((flash / 0.2 * 70).round().clamp(0, 255).toInt());
      canvas.drawRect(rect, _p);
    }

    // خطر: الجدار شبه منهار.
    if (engine.wall.fraction < 0.25 && !engine.gameOver) {
      final double pulse = 0.5 + 0.5 * math.sin(engine.time * 6);
      _p.color = AppColors.danger.withAlpha((pulse * 40).round());
      canvas.drawRect(rect, _p);
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
