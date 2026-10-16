import 'constants.dart';

/// الجدار الدائري في وسط الشاشة. إذا انهار تخسر الجولة.
class Wall {
  Wall({this.level = 0})
      : maxHealth = GameConst.wallBaseHealth * (1 + 0.25 * level),
        health = GameConst.wallBaseHealth * (1 + 0.25 * level);

  /// مستوى تحسين الجدار المشترى من المتجر.
  final int level;

  final double maxHealth;
  double health;

  final double x = GameConst.wallCenterX;
  final double y = GameConst.wallCenterY;
  final double radius = GameConst.wallRadius;

  /// وميض أحمر عند تلقي الضرر (يستخدمه الرسم).
  double hitFlash = 0;

  bool get destroyed => health <= 0;

  /// نسبة الصحة من 0 إلى 1.
  double get fraction => (health / maxHealth).clamp(0.0, 1.0).toDouble();

  void takeDamage(double amount) {
    if (amount <= 0 || destroyed) return;
    health -= amount;
    if (health < 0) health = 0;
    hitFlash = 0.15;
  }

  void repair(double amount) {
    if (amount <= 0 || destroyed) return;
    health += amount;
    if (health > maxHealth) health = maxHealth;
  }

  void update(double dt) {
    if (hitFlash > 0) {
      hitFlash -= dt;
      if (hitFlash < 0) hitFlash = 0;
    }
  }
}
