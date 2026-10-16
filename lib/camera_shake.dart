import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'constants.dart';

/// اهتزاز الكاميرا عند الانفجارات والضربات.
/// يتراكم الاهتزاز عند الاستدعاء المتكرر ثم يخفت تدريجياً.
class CameraShake {
  final math.Random _rnd = math.Random();

  /// أقصى قوة اهتزاز (بوحدات العالم) حتى لا تصبح الشاشة غير مقروءة.
  static const double maxIntensity = 22;

  double _intensity = 0;
  Offset _offset = Offset.zero;

  /// الإزاحة الحالية التي يطبّقها الرسم على الكاميرا.
  Offset get offset => _offset;

  /// هل الاهتزاز نشط الآن.
  bool get active => _intensity > 0.2;

  /// إضافة اهتزاز. القيم الصغيرة (2-3) للإصابات، والكبيرة (15+) للزعيم.
  void add(double amount) {
    if (amount <= 0) return;
    _intensity = math.min(maxIntensity, _intensity + amount);
  }

  void update(double dt) {
    if (_intensity <= 0.2) {
      _intensity = 0;
      _offset = Offset.zero;
      return;
    }
    _offset = Offset(
      (_rnd.nextDouble() * 2 - 1) * _intensity,
      (_rnd.nextDouble() * 2 - 1) * _intensity,
    );
    // يخفت بشكل أسي مع الوقت.
    _intensity -= _intensity * GameConst.shakeDecay * dt;
  }

  void reset() {
    _intensity = 0;
    _offset = Offset.zero;
  }
}
