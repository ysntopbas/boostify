import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:boostify/screens/home_screen.dart';
import 'package:boostify/services/optimize_service.dart';
import 'package:boostify/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await OptimizeService.init();

  final themeMode = await ThemeService.getThemeMode();

  runApp(EasyLocalization(
    supportedLocales: const [
      Locale('en'),
      Locale('tr'),
    ],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: MyApp(initialThemeMode: themeMode),
  ));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  
  const MyApp({
    super.key,
    required this.initialThemeMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemeService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boostify',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: _themeMode,
      theme: ThemeService.getLightTheme(),
      darkTheme: ThemeService.getDarkTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(onThemeChanged: _setThemeMode),
      },
    );
  }
}
