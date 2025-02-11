import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  void _restartApp(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(context.locale.languageCode == 'tr' ? 'turkish'.tr() : 'english'.tr()),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('language_settings'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Türkçe'),
                        leading: Radio<String>(
                          value: 'tr',
                          groupValue: context.locale.languageCode,
                          onChanged: (value) async {
                            await context.setLocale(const Locale('tr'));
                            if (context.mounted) {
                              Navigator.pop(context);
                              _restartApp(context);
                            }
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('English'),
                        leading: Radio<String>(
                          value: 'en',
                          groupValue: context.locale.languageCode,
                          onChanged: (value) async {
                            await context.setLocale(const Locale('en'));
                            if (context.mounted) {
                              Navigator.pop(context);
                              _restartApp(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              currentThemeMode == ThemeMode.dark 
                ? Icons.dark_mode 
                : Icons.light_mode
            ),
            title: Text('theme'.tr()),
            subtitle: Text(
              currentThemeMode == ThemeMode.dark 
                ? 'dark_theme'.tr() 
                : 'light_theme'.tr()
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('theme_settings'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('light_theme'.tr()),
                        leading: Radio<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: currentThemeMode,
                          onChanged: (value) {
                            onThemeChanged(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('dark_theme'.tr()),
                        leading: Radio<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: currentThemeMode,
                          onChanged: (value) {
                            onThemeChanged(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 