/// أرقام ضبط اللعبة في مكان واحد حتى يسهل تعديل الصعوبة لاحقاً.
class GameConst {
  GameConst._();

  // ---- العالم ----
  /// أبعاد العالم المنطقي (عمودي). يُرسم مقياساً على أي شاشة.
  static const double worldWidth = 400;
  static const double worldHeight = 800;

  /// مركز الجدار (دائري يحمي المدينة في وسط الشاشة).
  static const double wallCenterX = worldWidth / 2;
  static const double wallCenterY = worldHeight / 2;
  static const double wallRadius = 70;
  static const double wallBaseHealth = 1000;

  // ---- اللاعب ----
  static const double playerRadius = 14;
  static const double playerSpeed = 170;
  static const double playerBaseHealth = 100;

  /// أقصى بعد يستطيع اللاعب الابتعاد به عن مركز الجدار.
  static const double playerMaxDistance = 300;

  // ---- الرصاص ----
  static const double bulletSpeed = 520;
  static const double bulletLife = 1.1; // ثانية
  static const double bulletRadius = 3;

  // ---- العمالقة ----
  /// الضرر المضاعف عند إصابة نقطة الضعف.
  static const double weakSpotMultiplier = 4;

  /// نصف قطر نقطة الضعف مقارنة بحجم العملاق.
  static const double weakSpotRatio = 0.35;

  /// حد أقصى لعدد العمالقة على الشاشة للحفاظ على السلاسة.
  static const int maxGiants = 40;

  // ---- الموجات ----
  static const double timeBetweenWaves = 4; // ثانية
  static const int bossEveryWaves = 5;
  static const int baseGiantsPerWave = 5;
  static const int extraGiantsPerWave = 3;

  /// نسبة زيادة صحة العمالقة مع كل موجة.
  static const double healthGrowthPerWave = 0.12;

  // ---- المكافآت ----
  static const int pointsPerGiantBase = 10;
  static const double repairPickupAmount = 120;
  static const double healPickupAmount = 35;
  static const double pickupDropChance = 0.12;
  static const double pickupLife = 8; // ثانية قبل اختفائها

  // ---- التأثيرات ----
  static const int maxParticles = 220;
  static const double shakeDecay = 6;
}

/// أنواع العمالقة.
enum GiantType {
  crawler, // زاحف: بطيء وضعيف وبأعداد كبيرة
  runner, // راكض: سريع ودمه قليل
  armored, // مدرّع: دمه كثير ونقطة ضعفه تظهر في أوقات معينة
  boss, // زعيم: ضخم يظهر كل 5 موجات
}

/// الأسلحة بالترتيب الذي تُفتح به.
enum WeaponType {
  pistol, // مسدس
  rifle, // بندقية
  shotgun, // شوزن
  launcher, // قاذفة
}

/// مفاتيح الحفظ على الجوال.
class SaveKeys {
  SaveKeys._();

  static const String bestWave = 'best_wave';
  static const String bestScore = 'best_score';
  static const String coins = 'coins';
  static const String weaponsOwned = 'weapons_owned';
  static const String currentWeapon = 'current_weapon';
  static const String damageLevel = 'damage_level';
  static const String fireRateLevel = 'fire_rate_level';
  static const String wallLevel = 'wall_level';
  static const String soundOn = 'sound_on';
  static const String vibrationOn = 'vibration_on';
}
