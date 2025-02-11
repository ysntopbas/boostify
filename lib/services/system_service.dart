import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'platform/android_service.dart';

class SystemService {
  static Future<double> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync(recursive: true, followLinks: false);
      double totalSize = 0;
      
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      // Byte'ı MB'a çevirme
      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }

  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (e) {
      // Hata durumunda işlem yapılmayacak
    }
  }

  static Future<double> getRamUsage() async {
    if (Platform.isAndroid) {
      return AndroidService.getRamUsage();
    }
    return 0.7; // iOS için şimdilik sabit değer
  }

  static Future<void> cleanRam() async {
    if (Platform.isAndroid) {
      await AndroidService.cleanRam();
    }
  }

  static Future<void> optimizeSystem() async {
    try {
      // Arka plan uygulamalarını kapat
      await AndroidService.killBackgroundProcesses();
      
      // RAM'i temizle
      await AndroidService.cleanRam();
      
      // Uygulama önbelleğini temizle
      await AndroidService.clearAppCache();
      
      // Sistem önbelleğini temizle
      await clearCache();
    } catch (e) {
      // Hata durumunda işlem yapılmayacak
    }
  }
} 