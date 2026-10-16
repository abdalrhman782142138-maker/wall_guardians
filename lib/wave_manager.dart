import 'dart:math' as math;

import 'constants.dart';
import 'giant.dart';

enum _Phase {
  intermission, // استراحة بين الموجات
  spawning, // العمالقة يظهرون تدريجياً
  fighting, // كل العمالقة ظهروا وننتظر القضاء عليهم
}

/// يدير الموجات: عدد العمالقة، أنواعهم، وتوقيت ظهورهم من أطراف الشاشة.
class WaveManager {
  final math.Random _rnd = math.Random();

  /// رقم الموجة الحالية (يبدأ من 0 قبل أول موجة).
  int wave = 0;

  _Phase _phase = _Phase.intermission;
  double _timer = 2; // استراحة قصيرة قبل أول موجة
  double _spawnTimer = 0;
  double _spawnInterval = 1;
  final List<GiantType> _queue = <GiantType>[];

  bool _startedFlag = false;
  bool _clearedFlag = false;

  /// عدد العمالقة المتبقين للظهور في الموجة الحالية.
  int get remainingToSpawn => _queue.length;

  /// ثواني الاستراحة المتبقية (للعرض في الواجهة).
  double get intermissionLeft =>
      _phase == _Phase.intermission ? _timer.clamp(0, 99).toDouble() : 0;

  bool get isIntermission => _phase == _Phase.intermission;

  bool get isBossWave => wave > 0 && wave % GameConst.bossEveryWaves == 0;

  /// تُرجع true مرة واحدة عند بدء موجة جديدة.
  bool consumeWaveStarted() {
    final bool v = _startedFlag;
    _startedFlag = false;
    return v;
  }

  /// تُرجع true مرة واحدة عند القضاء على موجة كاملة.
  bool consumeWaveCleared() {
    final bool v = _clearedFlag;
    _clearedFlag = false;
    return v;
  }

  /// تحديث الموجات. ترجع العمالقة الجدد الذين يجب إضافتهم للعبة.
  /// [alive] عدد العمالقة الأحياء الآن، [capacity] المساحة المتبقية لهم.
  List<Giant> update(double dt, int alive, int capacity) {
    final List<Giant> spawned = <Giant>[];

    switch (_phase) {
      case _Phase.intermission:
        _timer -= dt;
        if (_timer <= 0) {
          _startWave();
        }
        break;

      case _Phase.spawning:
        _spawnTimer -= dt;
        int room = capacity;
        while (_spawnTimer <= 0 && _queue.isNotEmpty && room > 0) {
          spawned.add(_spawnOne(_queue.removeAt(0)));
          _spawnTimer += _spawnInterval;
          room--;
        }
        // إذا لم يبقَ مكان ننتظر دون تراكم الوقت.
        if (_spawnTimer < 0) _spawnTimer = 0;
        if (_queue.isEmpty) {
          _phase = _Phase.fighting;
        }
        break;

      case _Phase.fighting:
        if (alive == 0 && spawned.isEmpty) {
          _clearedFlag = true;
          _phase = _Phase.intermission;
          _timer = GameConst.timeBetweenWaves;
        }
        break;
    }

    return spawned;
  }

  // ======================================================
  //                     بناء الموجة
  // ======================================================

  void _startWave() {
    wave++;
    _queue
      ..clear()
      ..addAll(_buildQueue(wave));

    _spawnInterval = math.max(0.3, 1.1 - wave * 0.05);
    _spawnTimer = 0.3;
    _phase = _Phase.spawning;
    _startedFlag = true;
  }

  List<GiantType> _buildQueue(int w) {
    final bool boss = w % GameConst.bossEveryWaves == 0;

    int count =
        GameConst.baseGiantsPerWave + GameConst.extraGiantsPerWave * (w - 1);
    if (count > 60) count = 60;
    if (boss) count = (count * 0.6).round(); // موجة الزعيم أقل عدداً

    final List<GiantType> list = <GiantType>[];
    for (int i = 0; i < count; i++) {
      list.add(_pickType(w));
    }
    if (boss) {
      list.add(GiantType.boss);
    }
    return list;
  }

  /// اختيار نوع العملاق حسب رقم الموجة:
  /// الزواحف من البداية، الراكضون من الموجة 2، المدرّعون من الموجة 4.
  GiantType _pickType(int w) {
    final double r = _rnd.nextDouble();

    if (w >= 4) {
      if (r < 0.15 + math.min(0.15, w * 0.01)) return GiantType.armored;
      if (r < 0.50) return GiantType.runner;
      return GiantType.crawler;
    }
    if (w >= 2) {
      if (r < 0.35) return GiantType.runner;
      return GiantType.crawler;
    }
    return GiantType.crawler;
  }

  // ======================================================
  //                   مكان الظهور
  // ======================================================

  /// يظهر العملاق خارج الشاشة من حافة عشوائية.
  Giant _spawnOne(GiantType type) {
    const double w = GameConst.worldWidth;
    const double h = GameConst.worldHeight;
    const double margin = 50;

    double x;
    double y;
    switch (_rnd.nextInt(4)) {
      case 0: // أعلى
        x = _rnd.nextDouble() * w;
        y = -margin;
        break;
      case 1: // أسفل
        x = _rnd.nextDouble() * w;
        y = h + margin;
        break;
      case 2: // يسار
        x = -margin;
        y = _rnd.nextDouble() * h;
        break;
      default: // يمين
        x = w + margin;
        y = _rnd.nextDouble() * h;
        break;
    }

    return Giant(type: type, x: x, y: y, wave: wave);
  }
}
