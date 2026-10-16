import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'constants.dart';
import 'giant.dart';
import 'theme.dart';

/// يرسم العملاق بمنظور علوي بالكود فقط (بدون صور).
/// في الإحداثيات المحلية: محور x يشير إلى اتجاه النظر (نحو الجدار).
class GiantPainter {
  GiantPainter._();

  static final Paint _p = Paint();

  static void paint(Canvas canvas, Giant g, double time) {
    final double r = g.radius;

    // ---- الظل ----
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0x55000000);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(g.x + 3, g.y + 5), width: r * 2.2, height: r * 2.2),
      _p,
    );

    canvas.save();
    canvas.translate(g.x, g.y);
    canvas.rotate(g.angle);

    final Color skin = _skinColor(g);
    final Color dark = Color.lerp(skin, Colors.black, 0.35) ?? skin;
    final bool attacking = g.attacking;

    // ---- الذراعان (تتحركان أثناء المشي وتمتدان عند الهجوم) ----
    final double swing = math.sin(g.walkPhase * (attacking ? 2.2 : 1.0)) *
        r *
        (attacking ? 0.35 : 0.25);
    final double reach = attacking ? r * 0.35 : 0;
    _arm(canvas, Offset(r * 0.7 + swing + reach, -r * 0.85), r, dark);
    _arm(canvas, Offset(r * 0.7 - swing + reach, r * 0.85), r, dark);

    // ---- الجسم والكتفان ----
    final Rect bodyRect =
        Rect.fromCenter(center: Offset.zero, width: r * 1.25, height: r * 2.0);
    _p
      ..style = PaintingStyle.fill
      ..color = skin;
    canvas.drawOval(bodyRect, _p);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = dark;
    canvas.drawOval(bodyRect, _p);

    // ---- دروع المدرّع ----
    if (g.type == GiantType.armored) {
      _p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF5C6068);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(-r * 0.15, 0), width: r * 0.75, height: r * 1.75),
          Radius.circular(r * 0.2),
        ),
        _p,
      );
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A3D43);
      canvas.drawLine(Offset(-r * 0.15, -r * 0.8), Offset(-r * 0.15, r * 0.8), _p);
    }

    // ---- الرأس والشعر والعينان ----
    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2A1D17);
    canvas.drawCircle(Offset(r * 0.28, 0), r * 0.44, _p);
    _p.color = Color.lerp(skin, Colors.white, 0.12) ?? skin;
    canvas.drawCircle(Offset(r * 0.38, 0), r * 0.37, _p);
    _p.color = g.isBoss ? const Color(0xFFFF1744) : const Color(0xFFF5F0E6);
    canvas.drawCircle(Offset(r * 0.58, -r * 0.14), r * 0.07, _p);
    canvas.drawCircle(Offset(r * 0.58, r * 0.14), r * 0.07, _p);

    // ---- نقطة الضعف ----
    final Offset weakLocal = Offset(-r * 0.75, 0);
    final double wr = g.weakSpotRadius;
    if (g.weakVulnerable) {
      final double pulse = 0.75 + 0.25 * math.sin(time * 7 + g.walkPhase);
      _p
        ..style = PaintingStyle.fill
        ..color = AppColors.weakSpot.withAlpha((90 * pulse).round());
      canvas.drawCircle(weakLocal, wr * 1.9, _p);
      _p.color = AppColors.weakSpot;
      canvas.drawCircle(weakLocal, wr, _p);
      _p.color = const Color(0xFFFFCDD2);
      canvas.drawCircle(weakLocal, wr * 0.4, _p);
    } else {
      // درع يغطي نقطة الضعف.
      _p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF6E727A);
      canvas.drawCircle(weakLocal, wr * 1.25, _p);
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A3D43);
      canvas.drawCircle(weakLocal, wr * 1.25, _p);
    }

    // ---- وميض الإصابة ----
    if (g.hitFlash > 0) {
      _p
        ..style = PaintingStyle.fill
        ..color = const Color(0x55FFFFFF);
      canvas.drawOval(bodyRect, _p);
    }

    canvas.restore();

    _healthBar(canvas, g);
  }

  static Color _skinColor(Giant g) {
    switch (g.type) {
      case GiantType.crawler:
        return AppColors.giantSkin;
      case GiantType.runner:
        return const Color(0xFFC9A58C);
      case GiantType.armored:
        return const Color(0xFF9A7A68);
      case GiantType.boss:
        return const Color(0xFF8E5B49);
    }
  }

  static void _arm(Canvas canvas, Offset center, double r, Color color) {
    _p
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: r * 1.0, height: r * 0.34),
        Radius.circular(r * 0.17),
      ),
      _p,
    );
  }

  /// شريط صحة يظهر للزعيم والمدرّع دائماً، ولغيرهما عند الإصابة.
  static void _healthBar(Canvas canvas, Giant g) {
    final bool always =
        g.type == GiantType.boss || g.type == GiantType.armored;
    if (!always && g.fraction >= 1) return;

    final double w = g.radius * 1.7;
    const double h = 4;
    final double left = g.x - w / 2;
    final double top = g.y - g.radius - 12;

    _p
      ..style = PaintingStyle.fill
      ..color = const Color(0xAA000000);
    canvas.drawRect(Rect.fromLTWH(left - 1, top - 1, w + 2, h + 2), _p);
    _p.color = g.isBoss ? const Color(0xFFFF5252) : AppColors.weakSpot;
    canvas.drawRect(Rect.fromLTWH(left, top, w * g.fraction, h), _p);
  }
}
