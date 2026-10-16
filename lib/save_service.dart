import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// حفظ تقدم اللاعب على الجوال بدون إنترنت.
/// إذا فشل التحميل تعمل اللعبة بقيم افتراضية في الذاكرة فقط.
class SaveService extends ChangeNotifier {
  SaveService._();
  static final SaveService instance = SaveService._();

  SharedPreferences? _prefs;

  int _bestWave = 0;
  int _bestScore = 0;
  int _coins = 0;
  Set<int> _weaponsOwned = <int>{0}; // المسدس مملوك من البداية
  int _currentWeapon = 0;
  int _damageLevel = 0;
  int _fireRateLevel = 0;
  int _wallLevel = 0;
  bool _soundOn = true;
  bool _vibrationOn = true;

  int get bestWave => _bestWave;
  int get bestScore => _bestScore;
  int get coins => _coins;
  int get currentWeapon => _currentWeapon;
  int get damageLevel => _damageLevel;
  int get fireRateLevel => _fireRateLevel;
  int get wallLevel => _wallLevel;
  bool get soundOn => _soundOn;
  bool get vibrationOn => _vibrationOn;

  WeaponType get currentWeaponType => WeaponType.values[_currentWeapon];

  bool ownsWeapon(WeaponType type) => _weaponsOwned.contains(type.index);

  /// تحميل البيانات المحفوظة عند فتح اللعبة.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    _bestWave = prefs.getInt(SaveKeys.bestWave) ?? 0;
    _bestScore = prefs.getInt(SaveKeys.bestScore) ?? 0;
    _coins = prefs.getInt(SaveKeys.coins) ?? 0;
    _currentWeapon = prefs.getInt(SaveKeys.currentWeapon) ?? 0;
    _damageLevel = prefs.getInt(SaveKeys.damageLevel) ?? 0;
    _fireRateLevel = prefs.getInt(SaveKeys.fireRateLevel) ?? 0;
    _wallLevel = prefs.getInt(SaveKeys.wallLevel) ?? 0;
    _soundOn = prefs.getBool(SaveKeys.soundOn) ?? true;
    _vibrationOn = prefs.getBool(SaveKeys.vibrationOn) ?? true;

    final List<String>? owned = prefs.getStringList(SaveKeys.weaponsOwned);
    if (owned != null) {
      _weaponsOwned = owned
          .map((String s) => int.tryParse(s))
          .whereType<int>()
          .where((int i) => i >= 0 && i < WeaponType.values.length)
          .toSet();
    }
    // المسدس دائماً مملوك، والسلاح الحالي يجب أن يكون مملوكاً.
    _weaponsOwned.add(0);
    if (_currentWeapon < 0 ||
        _currentWeapon >= WeaponType.values.length ||
        !_weaponsOwned.contains(_currentWeapon)) {
      _currentWeapon = 0;
    }
    notifyListeners();
  }

  // ---------------- العملات ----------------

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _saveInt(SaveKeys.coins, _coins);
    notifyListeners();
  }

  /// يخصم المبلغ إذا كان الرصيد كافياً، ويرجع false إذا لم يكن كافياً.
  bool spendCoins(int amount) {
    if (amount < 0 || _coins < amount) return false;
    _coins -= amount;
    _saveInt(SaveKeys.coins, _coins);
    notifyListeners();
    return true;
  }

  // ---------------- الأسلحة ----------------

  /// شراء سلاح بسعر معيّن. يرجع true عند النجاح.
  bool buyWeapon(WeaponType type, int price) {
    if (ownsWeapon(type)) return false;
    if (!spendCoins(price)) return false;
    _weaponsOwned.add(type.index);
    _saveWeapons();
    notifyListeners();
    return true;
  }

  void equipWeapon(WeaponType type) {
    if (!ownsWeapon(type)) return;
    _currentWeapon = type.index;
    _saveInt(SaveKeys.currentWeapon, _currentWeapon);
    notifyListeners();
  }

  // ---------------- التحسينات ----------------

  bool upgradeDamage(int price) {
    if (!spendCoins(price)) return false;
    _damageLevel++;
    _saveInt(SaveKeys.damageLevel, _damageLevel);
    notifyListeners();
    return true;
  }

  bool upgradeFireRate(int price) {
    if (!spendCoins(price)) return false;
    _fireRateLevel++;
    _saveInt(SaveKeys.fireRateLevel, _fireRateLevel);
    notifyListeners();
    return true;
  }

  bool upgradeWall(int price) {
    if (!spendCoins(price)) return false;
    _wallLevel++;
    _saveInt(SaveKeys.wallLevel, _wallLevel);
    notifyListeners();
    return true;
  }

  // ---------------- النتائج ----------------

  /// يُستدعى عند نهاية كل جولة لتسجيل الأرقام القياسية.
  void recordRun({required int wave, required int score}) {
    if (wave > _bestWave) {
      _bestWave = wave;
      _saveInt(SaveKeys.bestWave, _bestWave);
    }
    if (score > _bestScore) {
      _bestScore = score;
      _saveInt(SaveKeys.bestScore, _bestScore);
    }
    notifyListeners();
  }

  // ---------------- الإعدادات ----------------

  void setSound(bool value) {
    _soundOn = value;
    _saveBool(SaveKeys.soundOn, value);
    notifyListeners();
  }

  void setVibration(bool value) {
    _vibrationOn = value;
    _saveBool(SaveKeys.vibrationOn, value);
    notifyListeners();
  }

  /// مسح كل التقدم والبدء من جديد.
  Future<void> resetAll() async {
    _bestWave = 0;
    _bestScore = 0;
    _coins = 0;
    _weaponsOwned = <int>{0};
    _currentWeapon = 0;
    _damageLevel = 0;
    _fireRateLevel = 0;
    _wallLevel = 0;
    try {
      await _prefs?.clear();
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- أدوات داخلية ----------------

  void _saveInt(String key, int value) {
    try {
      _prefs?.setInt(key, value);
    } catch (_) {}
  }

  void _saveBool(String key, bool value) {
    try {
      _prefs?.setBool(key, value);
    } catch (_) {}
  }

  void _saveWeapons() {
    try {
      _prefs?.setStringList(
        SaveKeys.weaponsOwned,
        _weaponsOwned.map((int i) => i.toString()).toList(),
      );
    } catch (_) {}
  }
}
