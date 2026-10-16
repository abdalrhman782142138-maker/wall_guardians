import 'dart:math' as math;

/// دوال التصادم البسيطة المستخدمة في المحرك.
/// كل الكائنات دوائر، فالحساب سريع ومناسب للجوال.
class Collision {
  Collision._();

  /// هل تتداخل دائرتان؟ (مقارنة المربعات لتجنب الجذر التربيعي)
  static bool circles(
    double ax,
    double ay,
    double ar,
    double bx,
    double by,
    double br,
  ) {
    final double dx = bx - ax;
    final double dy = by - ay;
    final double r = ar + br;
    return dx * dx + dy * dy <= r * r;
  }

  /// المسافة بين نقطتين.
  static double distance(double ax, double ay, double bx, double by) {
    final double dx = bx - ax;
    final double dy = by - ay;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// الزاوية من النقطة الأولى نحو الثانية (بالراديان).
  static double angleTo(double ax, double ay, double bx, double by) {
    return math.atan2(by - ay, bx - ax);
  }
}
