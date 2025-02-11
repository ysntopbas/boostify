import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        backgroundColor: Colors.transparent,
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
        ],
      ),
    );
  }
} 