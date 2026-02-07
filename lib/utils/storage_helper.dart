import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

/// Helper class for persistent storage using SharedPreferences
class StorageHelper {
  static const String _savedPlayersKey = 'saved_players';
  static const String _playerRecordsKey = 'player_records';
  static const String _settingsKey = 'settings';

  /// Get saved player names
  static Future<List<String>> getSavedPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedPlayersKey) ?? [];
  }

  /// Save player names
  static Future<void> savePlayerNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedPlayersKey, names);
  }

  /// Add a player name to saved list
  static Future<void> addPlayerName(String name) async {
    final names = await getSavedPlayerNames();
    if (!names.contains(name)) {
      names.add(name);
      await savePlayerNames(names);
    }
  }

  /// Remove a player name from saved list
  static Future<void> removePlayerName(String name) async {
    final names = await getSavedPlayerNames();
    names.remove(name);
    await savePlayerNames(names);
  }

  /// Get player records
  static Future<Map<String, Map<String, dynamic>>> getPlayerRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_playerRecordsKey);
    if (jsonStr == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  /// Save player records
  static Future<void> savePlayerRecords(
    Map<String, Map<String, dynamic>> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerRecordsKey, jsonEncode(records));
  }

  /// Update a player's record after a game
  static Future<void> updatePlayerRecord(Player player, bool won) async {
    final records = await getPlayerRecords();

    final existing =
        records[player.name] ??
        {'gamesPlayed': 0, 'gamesWon': 0, 'allTimeHighestStock': 0};

    existing['gamesPlayed'] = (existing['gamesPlayed'] as int) + 1;
    if (won) {
      existing['gamesWon'] = (existing['gamesWon'] as int) + 1;
    }
    if (player.allTimeHighestStock > (existing['allTimeHighestStock'] as int)) {
      existing['allTimeHighestStock'] = player.allTimeHighestStock;
    }

    records[player.name] = existing;
    await savePlayerRecords(records);
  }

  /// Get settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr == null) {
      return {
        'totalRounds': 20,
        'oneStockPerRoll': false,
        'soundEnabled': true,
        'darkMode': null, // null = system default
      };
    }
    return jsonDecode(jsonStr);
  }

  /// Save settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  /// Clear all saved player names
  static Future<void> clearSavedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPlayersKey);
  }

  /// Clear all player records
  static Future<void> clearPlayerRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerRecordsKey);
  }
}
