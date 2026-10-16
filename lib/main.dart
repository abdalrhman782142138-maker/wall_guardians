import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'menu_page.dart';
import 'save_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // اللعبة بمنظور علوي وتعمل بوضع عمودي فقط.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // وضع ملء الشاشة بدون أزرار النظام أثناء اللعب.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await SaveService.instance.init();
  } catch (_) {
    // إذا فشل تحميل البيانات تعمل اللعبة ببيانات فارغة بدل أن تتوقف.
  }

  runApp(const WallGuardiansApp());
}

class WallGuardiansApp extends StatelessWidget {
  const WallGuardiansApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حرّاس الجدار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // واجهة عربية من اليمين إلى اليسار.
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MenuPage(),
    );
  }
}