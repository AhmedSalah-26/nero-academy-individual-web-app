import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/app_logger.dart';
import '../models/portfolio_model.dart';

/// Portfolio Local Data Source
abstract class PortfolioLocalDataSource {
  Future<PortfolioModel?> getCachedPortfolio(String userId);
  Future<void> cachePortfolio(PortfolioModel portfolio);
  Future<void> clearCache();
}

/// Portfolio Local Data Source Implementation
class PortfolioLocalDataSourceImpl implements PortfolioLocalDataSource {
  final SharedPreferences prefs;

  static const String _portfolioKey = 'cached_portfolio_';

  PortfolioLocalDataSourceImpl({required this.prefs});

  @override
  Future<PortfolioModel?> getCachedPortfolio(String userId) async {
    AppLogger.i('💾 [PortfolioLocal] Getting cached portfolio for: $userId');

    final jsonString = prefs.getString('$_portfolioKey$userId');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PortfolioModel.fromJson(json);
    } catch (e) {
      AppLogger.e('[PortfolioLocal] Error parsing cached portfolio: $e');
      return null;
    }
  }

  @override
  Future<void> cachePortfolio(PortfolioModel portfolio) async {
    AppLogger.i(
        '💾 [PortfolioLocal] Caching portfolio for: ${portfolio.userId}');

    final jsonString = jsonEncode(portfolio.toJson());
    await prefs.setString('$_portfolioKey${portfolio.userId}', jsonString);
  }

  @override
  Future<void> clearCache() async {
    AppLogger.i('💾 [PortfolioLocal] Clearing cache');

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_portfolioKey)) {
        await prefs.remove(key);
      }
    }
  }
}
