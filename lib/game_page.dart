import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'game_engine.dart';
import 'game_over_overlay.dart';
import 'game_painter.dart';
import 'pause_overlay.dart';
import 'save_service.dart';
import 'shop_page.dart';
import 'theme.dart';

/// شاشة اللعب: الرسم + الواجهة العلوية + عصا الحركة + زر النار.
class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GameEngine engine = GameEngine();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  int _prevBestScore = 0;
  int _prevBestWave = 0;

  final Stopwatch _fxClock = Stopwatch()..start();
  int _lastFxMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rememberRecords();
    engine.onEvent = _onGameEvent;
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    engine.onEvent = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إيقاف مؤقت تلقائي عند الخروج من التطبيق.
    if (state != AppLifecycleState.resumed && !engine.gameOver) {
      engine.pause();
    }
  }

  void _tick(Duration elapsed) {
    final double dt = (elapsed - _last).inMicroseconds / 1000000.0;
    _last = elapsed;
    engine.update(dt);
  }

  void _rememberRecords() {
    _prevBestScore = SaveService.instance.bestScore;
    _prevBestWave = SaveService.instance.bestWave;
  }

  void _restart() {
    engine.reset();
    _rememberRecords();
  }

  Future<void> _openShop() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopPage()),
    );
    if (!mounted) return;
    _restart(); // لتطبيق الأسلحة والتحسينات الجديدة
  }

  // ---------------- الصوت والاهتزاز ----------------

  void _onGameEvent(GameEvent e) {
    final int now = _fxClock.elapsedMilliseconds;
    if (now - _lastFxMs < 70) return; // لا نكثر المؤثرات
    final SaveService s = SaveService.instance;

    bool fx = true;
    if (s.vibrationOn) {
      switch (e) {
        case GameEvent.weakHit:
          HapticFeedback.selectionClick();
          break;
        case GameEvent.playerHit:
        case GameEvent.explosion:
          HapticFeedback.mediumImpact();
          break;
        case GameEvent.gameOver:
          HapticFeedback.heavyImpact();
          break;
        default:
          fx = false;
      }
    }
    if (s.soundOn) {
      switch (e) {
        case GameEvent.giantDie:
        case GameEvent.explosion:
        case GameEvent.waveStart:
          SystemSound.play(SystemSoundType.click);
          fx = true;
          break;
        default:
          break;
      }
    }
    if (fx) _lastFxMs = now;
  }

  // ---------------- البناء ----------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (engine.gameOver) {
          Navigator.of(context).pop();
        } else if (engine.paused) {
          engine.resume();
        } else {
          engine.pause();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: GamePainter(engine)),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: engine,
                builder: (BuildContext context, Widget? _) => _buildHud(),
              ),
            ),
            Positioned.fill(child: _buildControls()),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: engine,
                builder: (BuildContext context, Widget? _) =>
                    _buildOverlays(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- الواجهة العلوية ----------------

  Widget _buildHud() {
    final bool intermission = engine.waves.isIntermission && !engine.gameOver;
    final int nextWave = engine.wave + 1;
    final bool nextIsBoss = nextWave % GameConst.bossEveryWaves == 0;
    final int left = engine.giants.length + engine.waves.remainingToSpawn;

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Material(
                    color: const Color(0x99000000),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.pause_rounded),
                      color: AppColors.textPrimary,
                      onPressed: engine.gameOver ? null : engine.pause,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        _Bar(
                          icon: Icons.shield,
                          value: engine.wall.fraction,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 5),
                        _Bar(
                          icon: Icons.favorite,
                          value: engine.player.fraction,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _Chip(text: 'الموجة ${engine.wave}'),
                      const SizedBox(height: 4),
                      _Chip(text: '${engine.score}'),
                    ],
                  ),
                ],
              ),
            ),
            if (intermission)
              Align(
                alignment: const Alignment(0, -0.55),
                child: _Banner(
                  title: nextIsBoss
                      ? 'تحذير! زعيم قادم'
                      : 'الموجة $nextWave',
                  subtitle:
                      'تبدأ خلال ${engine.waves.intermissionLeft.ceil()}',
                  danger: nextIsBoss,
                ),
              ),
            if (!intermission && !engine.gameOver)
              Align(
                alignment: const Alignment(0, -0.88),
                child: Text(
                  'المتبقي: $left',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            if (engine.time < 8 && engine.wave <= 1 && !engine.gameOver)
              const Align(
                alignment: Alignment(0, 0.62),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'التصويب تلقائي. اضغط زر النار واستهدف النقطة الحمراء على ظهر العملاق!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- أدوات التحكم ----------------

  Widget _buildControls() {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 18,
            bottom: 22,
            child: _Joystick(onChanged: engine.setMove),
          ),
          Positioned(
            right: 24,
            bottom: 34,
            child: _FireButton(onChanged: engine.setFiring),
          ),
        ],
      ),
    );
  }

  // ---------------- النوافذ فوق اللعبة ----------------

  Widget _buildOverlays() {
    if (engine.gameOver) {
      return GameOverOverlay(
        wave: engine.wave,
        score: engine.score,
        coins: engine.coinsEarned,
        kills: engine.kills,
        newRecord: engine.score > 0 && engine.score > _prevBestScore,
        newWaveRecord: engine.wave > _prevBestWave,
        onRestart: _restart,
        onShop: _openShop,
        onExit: () => Navigator.of(context).pop(),
      );
    }
    if (engine.paused) {
      return PauseOverlay(
        onResume: engine.resume,
        onRestart: _restart,
        onExit: () => Navigator.of(context).pop(),
      );
    }
    return const SizedBox.shrink();
  }
}

// ======================================================
//                    عناصر الواجهة
// ======================================================

class _Bar extends StatelessWidget {
  const _Bar({required this.icon, required this.value, required this.color});

  final IconData icon;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              minHeight: 9,
              backgroundColor: const Color(0x88000000),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.subtitle,
    required this.danger,
  });

  final String title;
  final String subtitle;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color = danger ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// عصا التحكم. تعمل بمؤشر لمس مستقل حتى يمكن الضغط على زر النار معها.
class _Joystick extends StatefulWidget {
  const _Joystick({required this.onChanged});

  final ValueChanged<Offset> onChanged;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _size = 140;
  static const double _knob = 30;

  Offset _offset = Offset.zero;
  int? _pointer;

  void _update(Offset local) {
    const Offset center = Offset(_size / 2, _size / 2);
    const double maxR = _size / 2 - 12;
    Offset d = local - center;
    if (d.distance > maxR) d = d / d.distance * maxR;
    setState(() => _offset = d);
    widget.onChanged(d / maxR);
  }

  void _release(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    setState(() => _offset = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) {
        _pointer ??= e.pointer;
        if (_pointer == e.pointer) _update(e.localPosition);
      },
      onPointerMove: (PointerMoveEvent e) {
        if (_pointer == e.pointer) _update(e.localPosition);
      },
      onPointerUp: _release,
      onPointerCancel: _release,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x33FFFFFF),
                border: Border.all(color: const Color(0x66FFFFFF), width: 2),
              ),
            ),
            Transform.translate(
              offset: _offset,
              child: Container(
                width: _knob * 2,
                height: _knob * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xAAC9A24B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر النار: الإطلاق مستمر طالما الإصبع مضغوط.
class _FireButton extends StatefulWidget {
  const _FireButton({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  State<_FireButton> createState() => _FireButtonState();
}

class _FireButtonState extends State<_FireButton> {
  bool _down = false;
  int? _pointer;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) {
        _pointer ??= e.pointer;
        if (_pointer == e.pointer) _set(true);
      },
      onPointerUp: (PointerUpEvent e) {
        if (_pointer == e.pointer) {
          _pointer = null;
          _set(false);
        }
      },
      onPointerCancel: (PointerCancelEvent e) {
        if (_pointer == e.pointer) {
          _pointer = null;
          _set(false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: _down ? 92 : 100,
        height: _down ? 92 : 100,
        margin: EdgeInsets.all(_down ? 4 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _down ? const Color(0xFFB71C1C) : const Color(0xCCE53935),
          border: Border.all(color: const Color(0x99FFFFFF), width: 2),
        ),
        child: const Icon(
          Icons.local_fire_department,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}
