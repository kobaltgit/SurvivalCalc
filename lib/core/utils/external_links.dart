import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Константы внешних ссылок и методы безопасного перехода
class ExternalLinks {
  const ExternalLinks._();

  /// Официальный Telegram-канал проекта
  static const String telegramChannel = 'https://t.me/survivalcalc';

  /// Исходный код на GitHub
  static const String githubRepo = 'https://github.com/kobaltgit/SurvivalCalc';

  /// Онлайн веб-версия (GitHub Pages)
  static const String webApp = 'https://kobaltgit.github.io/SurvivalCalc/';

  /// Прямая ссылка на скачивание APK релиза
  static const String apkRelease =
      'https://github.com/kobaltgit/SurvivalCalc/releases/latest/download/SurvivalCalc_v1.0.0.apk';

  /// Открыть ссылку во внешнем браузере или приложении
  static Future<bool> open(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('ExternalLinks: Ошибка открытия $url -> $e');
    }
    return false;
  }

  /// Открыть Telegram-канал
  static Future<bool> openTelegram() => open(telegramChannel);

  /// Открыть GitHub репозиторий
  static Future<bool> openGithub() => open(githubRepo);

  /// Открыть веб-версию
  static Future<bool> openWebApp() => open(webApp);

  /// Скачать APK
  static Future<bool> openApkDownload() => open(apkRelease);
}
