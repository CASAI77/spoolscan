import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyPrinterIp = 'printer_ip';
  static const defaultPrinterIp = '192.168.1.179';

  static const _keySpoolmanUrl = 'spoolman_url';
  static const defaultSpoolmanUrl = '192.168.1.181:7912';

  static const _keyLanguage = 'language';
  static const defaultLanguage = 'de';

  Future<String> getPrinterIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterIp) ?? defaultPrinterIp;
  }

  Future<void> setPrinterIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterIp, ip);
  }

  Future<String> getSpoolmanUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySpoolmanUrl) ?? defaultSpoolmanUrl;
  }

  Future<void> setSpoolmanUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySpoolmanUrl, url);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? defaultLanguage;
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
  }
}
