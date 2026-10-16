import 'dart:math' as math;
import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';

import 'bullet.dart';
import 'camera_shake.dart';
import 'collision.dart';
import 'constants.dart';
import 'giant.dart';
import 'particles.dart';
import 'pickup.dart';
import 'player.dart';
import 'save_service.dart';
import 'theme.dart';
import 'wall.dart';
import 'wave_manager.dart';

/// أحداث يرسلها المحرك للواجهة (للصوت والاهتزاز).
enum GameEvent {
  shoot,
  hit,
  weakHit,
  giantDie,
  wallHit,
  playerHit,
  pickup,
  waveStart,
  waveClear,
  explosion,
  gameOver,
}

/// محرك اللعبة: التحديث، التصادم، الموجات، النتيجة.
/// يستدعي notifyListeners كل إطار ليعيد الرسم والواجهة بناء نفسها.
class GameEngine extends ChangeNotifier {
  GameEngine() {
    reset();
  }

  final math.Random _rnd = math.Random();

  late Player player;
  late Wall wall;
  late WaveManager waves;

  final List<Giant> giants = <Giant>[];
  final List<Bullet> bullets = <Bullet>[];
  final List<Pickup> pickups = <Pickup>[];
  final ParticleSystem particles = ParticleSystem();
  final CameraShake shake = CameraShake();

  late WeaponData weapon;
  double damageMul = 1;
  double fireRateMul = 1;

  int score = 0;
  int coinsEarned = 0;
  int kills = 0;
  bool gameOver = false;
  bool paused = false;
  double time = 0;
  double muzzleFlash = 0;

  /// اتجاه عصا التحكم (طوله من 0 إلى 1).
  Offset moveInput = Offset.zero;

  /// هل زر الإطلاق مضغوط.
  bool firing = false;

  /// تستمع لها الواجهة لتشغيل الصوت والاهتزاز.
  void Function(GameEvent event)? onEvent;

  double _fireCooldown = 0;
  double _wallHitCooldown = 0;
  bool _saved = false;

  int get wave => waves.wave;

  /// بدء جولة جديدة بإعدادات اللاعب المحفوظة.
  void reset() {
    final SaveService save = SaveService.instance;
    weapon = WeaponData.of(save.currentWeaponType);
    damageMul = 1 + 0.2 * save.damageLevel;
    fireRateMul = 1 + 0.12 * save.fireRateLevel;

    player = Player();
    wall = Wall(level: save.wallLevel);
    waves = WaveManager();

    giants.clear();
    bullets.clear();
    pickups.clear();
    particles.clear();
    shake.reset();

    score = 0;
    coinsEarned = 0;
    kills = 0;
    gameOver = false;
    paused = false;
    time = 0;
    muzzleFlash = 0;
    moveInput = Offset.zero;
    firing = false;
    _fireCooldown = 0;
    _wallHitCooldown = 0;
    _saved = false;
    notifyListeners();
  }

  void setMove(Offset v) {
    final double len = v.distance;
    moveInput = len > 1 ? v / len : v;
  }

  void setFiring(bool value) {
    firing = value;
  }

  void pause() {
    paused = true;
    firing = false;
    moveInput = Offset.zero;
    notifyListeners();
  }

  void resume() {
    paused = false;
    notifyListeners();
  }

  // ======================================================
  //                    الحلقة الرئيسية
  // ======================================================

  void update(double rawDt) {
    if (gameOver || paused) return;
    final double dt = rawDt > 0.05 ? 0.05 : rawDt;

    time += dt;
    _fireCooldown -= dt;
    _wallHitCooldown -= dt;
    if (muzzleFlash > 0) muzzleFlash -= dt;

    // ---- اللاعب والتصويب التلقائي ----
    player.update(dt, moveInput);
    final Giant? target = _nearestGiant();
    if (target != null) {
      player.aimAngle = math.atan2(target.y - player.y, target.x - player.x);
    }

    // ---- الإطلاق ----
    if (firing && _fireCooldown <= 0) {
      _shoot();
    }

    // ---- الرصاص ----
    _updateBullets(dt);

    // ---- العمالقة ----
    bool wallAttacked = false;
    for (final Giant g in giants) {
      g.update(dt);
      if (g.attacking) {
        wall.takeDamage(g.wallDamage * dt);
        wallAttacked = true;
      }
      if (player.invincible <= 0 &&
          Collision.circles(player.x, player.y, player.radius, g.x, g.y,
              g.radius * 0.8)) {
        player.takeDamage(g.contactDamage);
        shake.add(6);
        particles.emit(player.x, player.y,
            count: 10, color: AppColors.danger, speed: 110, life: 0.4);
        _emit(GameEvent.playerHit);
      }
    }
    if (wallAttacked && _wallHitCooldown <= 0) {
      _wallHitCooldown = 0.4;
      shake.add(3);
      _emit(GameEvent.wallHit);
    }
    _separateGiants();

    // ---- موت العمالقة ----
    for (final Giant g in giants) {
      if (g.health <= 0 && !g.dead) {
        g.dead = true;
        _onGiantKilled(g);
      }
    }
    giants.removeWhere((Giant g) => g.dead);

    // ---- المكافآت ----
    for (final Pickup p in pickups) {
      p.update(dt);
      if (!p.dead &&
          Collision.circles(player.x, player.y, player.radius + 10, p.x, p.y,
              p.radius)) {
        _applyPickup(p);
      }
    }
    pickups.removeWhere((Pickup p) => p.dead);

    // ---- الموجات ----
    final int capacity = GameConst.maxGiants - giants.length;
    giants.addAll(waves.update(dt, giants.length, capacity));
    if (waves.consumeWaveStarted()) {
      _emit(GameEvent.waveStart);
    }
    if (waves.consumeWaveCleared()) {
      final int bonus = 15 + waves.wave * 5;
      score += bonus;
      coinsEarned += bonus;
      _emit(GameEvent.waveClear);
    }

    // ---- المؤثرات ----
    wall.update(dt);
    particles.update(dt);
    shake.update(dt);

    // ---- نهاية الجولة ----
    if (wall.destroyed || player.isDead) {
      _finish();
    }

    notifyListeners();
  }

  // ======================================================
  //                       الإطلاق
  // ======================================================

  void _shoot() {
    _fireCooldown = 1 / (weapon.fireRate * fireRateMul);
    for (int i = 0; i < weapon.pellets; i++) {
      final double a =
          player.aimAngle + (_rnd.nextDouble() - 0.5) * weapon.spread;
      bullets.add(Bullet(
        x: player.x + math.cos(a) * 18,
        y: player.y + math.sin(a) * 18,
        angle: a,
        speed: weapon.bulletSpeed,
        damage: weapon.damage * damageMul,
        explosionRadius: weapon.explosionRadius,
      ));
    }
    muzzleFlash = 0.06;
    shake.add(weapon.recoilShake);
    _emit(GameEvent.shoot);
  }

  Giant? _nearestGiant() {
    Giant? best;
    double bestD = double.infinity;
    for (final Giant g in giants) {
      final double dx = g.x - player.x;
      final double dy = g.y - player.y;
      final double d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return best;
  }

  // ======================================================
  //                  الرصاص والإصابات
  // ======================================================

  void _updateBullets(double dt) {
    for (final Bullet b in bullets) {
      b.update(dt);
      if (b.dead) continue;

      if (b.x < -30 ||
          b.x > GameConst.worldWidth + 30 ||
          b.y < -30 ||
          b.y > GameConst.worldHeight + 30) {
        b.dead = true;
        continue;
      }

      for (final Giant g in giants) {
        if (g.dead) continue;

        bool weak = false;
        bool hit = false;

        if (g.weakVulnerable) {
          final Offset wp = g.weakSpotPos;
          if (Collision.circles(
              b.x, b.y, b.radius, wp.dx, wp.dy, g.weakSpotRadius)) {
            weak = true;
            hit = true;
          }
        }
        if (!hit &&
            Collision.circles(b.x, b.y, b.radius, g.x, g.y, g.radius)) {
          hit = true;
        }
        if (!hit) continue;

        _hitGiant(g, b, weak);
        break; // الرصاصة استُهلكت
      }
    }
    bullets.removeWhere((Bullet b) => b.dead);
  }

  void _hitGiant(Giant g, Bullet b, bool weak) {
    b.dead = true;

    if (b.explosionRadius > 0) {
      _explode(b.x, b.y, b.explosionRadius, b.damage);
      return;
    }

    final double dmg = weak
        ? b.damage * GameConst.weakSpotMultiplier
        : b.damage * g.bodyDamageFactor;
    g.takeDamage(dmg);

    if (weak) {
      particles.emit(b.x, b.y,
          count: 12,
          color: AppColors.weakSpot,
          speed: 150,
          life: 0.45,
          size: 3.5);
      shake.add(2);
      _emit(GameEvent.weakHit);
    } else {
      particles.emit(b.x, b.y,
          count: 4,
          color: const Color(0xFF8E2B2B),
          speed: 90,
          life: 0.3,
          size: 2.5);
      _emit(GameEvent.hit);
    }
  }

  void _explode(double x, double y, double radius, double damage) {
    for (final Giant g in giants) {
      if (g.dead) continue;
      final double dx = g.x - x;
      final double dy = g.y - y;
      final double d = math.sqrt(dx * dx + dy * dy);
      final double reach = radius + g.radius;
      if (d > reach) continue;

      final double falloff = 1 - (d / reach) * 0.5;
      final double armorFactor = g.type == GiantType.armored ? 0.6 : 1.0;
      g.takeDamage(damage * falloff * armorFactor);
    }
    particles.emit(x, y,
        count: 28,
        color: const Color(0xFFFF9800),
        speed: 220,
        life: 0.6,
        size: 4);
    shake.add(7);
    _emit(GameEvent.explosion);
  }

  // ======================================================
  //                   موت العمالقة والمكافآت
  // ======================================================

  void _onGiantKilled(Giant g) {
    score += g.reward;
    coinsEarned += g.reward;
    kills++;

    final bool isBoss = g.type == GiantType.boss;
    particles.emit(g.x, g.y,
        count: isBoss ? 60 : 22,
        color: const Color(0xFFB71C1C),
        speed: isBoss ? 260 : 170,
        life: isBoss ? 0.9 : 0.6,
        size: isBoss ? 5 : 3.5);
    shake.add(isBoss ? 16 : 3);

    // إسقاط مكافأة: الزعيم يسقط ترميماً مضموناً.
    if (isBoss) {
      pickups.add(Pickup(type: PickupType.repair, x: g.x, y: g.y));
    } else if (_rnd.nextDouble() < GameConst.pickupDropChance) {
      final bool wallHurt = wall.fraction < 0.7;
      final PickupType t = (wallHurt && _rnd.nextDouble() < 0.6)
          ? PickupType.repair
          : PickupType.heal;
      pickups.add(Pickup(type: t, x: g.x, y: g.y));
    }
    _emit(GameEvent.giantDie);
  }

  void _applyPickup(Pickup p) {
    p.dead = true;
    if (p.type == PickupType.repair) {
      wall.repair(GameConst.repairPickupAmount);
    } else {
      player.heal(GameConst.healPickupAmount);
    }
    particles.emit(p.x, p.y,
        count: 12, color: AppColors.success, speed: 100, life: 0.5);
    _emit(GameEvent.pickup);
  }

  // ======================================================
  //                 منع تراكب العمالقة
  // ======================================================

  void _separateGiants() {
    final int n = giants.length;
    for (int i = 0; i < n; i++) {
      final Giant a = giants[i];
      for (int j = i + 1; j < n; j++) {
        final Giant b = giants[j];
        final double dx = b.x - a.x;
        final double dy = b.y - a.y;
        final double d = math.sqrt(dx * dx + dy * dy);
        final double minD = (a.radius + b.radius) * 0.8;
        if (d < minD && d > 0.001) {
          final double push = (minD - d) / 2;
          final double nx = dx / d;
          final double ny = dy / d;
          a.x -= nx * push;
          a.y -= ny * push;
          b.x += nx * push;
          b.y += ny * push;
        }
      }
    }
    for (final Giant g in giants) {
      g.clampOutsideWall();
    }
  }

  // ======================================================
  //                      النهاية
  // ======================================================

  void _finish() {
    if (gameOver) return;
    gameOver = true;
    firing = false;
    moveInput = Offset.zero;
    shake.add(18);

    if (!_saved) {
      _saved = true;
      SaveService.instance.recordRun(wave: waves.wave, score: score);
      SaveService.instance.addCoins(coinsEarned);
    }
    _emit(GameEvent.gameOver);
  }

  void _emit(GameEvent e) {
    final void Function(GameEvent event)? cb = onEvent;
    if (cb != null) cb(e);
  }
}
