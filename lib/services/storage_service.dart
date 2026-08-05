import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _conversionCountKey = 'conversion_count';

  static Future<int> getConversionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_conversionCountKey) ?? 0;
  }

  static Future<void> incrementConversionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getConversionCount();
    await prefs.setInt(_conversionCountKey, count + 1);
  }

  static Future<bool> shouldShowAd() async {
    final count = await getConversionCount();
    if (count == 0) return false;
    return count % 2 == 1;
  }
}
