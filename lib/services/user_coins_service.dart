import 'package:supabase_flutter/supabase_flutter.dart';

class UserCoinsService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'user_coins';
  static const String _txTable = 'user_coin_transactions';

  // Get user coins by username
  static Future<int> getCoins(String username) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('username', username)
          .maybeSingle();

      if (data != null) {
        return data['coins'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Get Coins Error: $e');
      return 0;
    }
  }

  // Get coin transactions history (most recent first)
  static Future<List<Map<String, dynamic>>> getTransactions(
    String username,
  ) async {
    try {
      final data = await _supabase
          .from(_txTable)
          .select()
          .eq('username', username)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Get Coin Transactions Error: $e');
      return [];
    }
  }

  // Internal helper to log a transaction
  static Future<void> _logTransaction({
    required String username,
    required int amount,
    required String type, // 'add' | 'spend'
    String? source,
  }) async {
    try {
      await _supabase.from(_txTable).insert({
        'username': username,
        'amount': amount,
        'type': type,
        'source': source ?? '',
      });
    } catch (e) {
      print('Log Coin Transaction Error: $e');
    }
  }

  // Add coins to user (updates existing record, user must exist in users table first)
  static Future<void> addCoins(String username, int coins) async {
    try {
      final currentCoins = await getCoins(username);
      final newCoins = currentCoins + coins;

      // Update the existing record for this username
      await _supabase
          .from(_tableName)
          .update({'coins': newCoins})
          .eq('username', username);
      // No default history log here. Use addCoinsWithSource() to record reason.
    } catch (e) {
      print('Add Coins Error: $e');
    }
  }

  // Spend coins (deduct from user)
  static Future<bool> spendCoins(String username, int coins) async {
    try {
      final currentCoins = await getCoins(username);

      if (currentCoins >= coins) {
        final newCoins = currentCoins - coins;
        await _supabase
            .from(_tableName)
            .update({'coins': newCoins})
            .eq('username', username);
        // No default history log here. Use spendCoinsWithSource() to record reason.
        return true;
      }

      print('Insufficient coins for user $username');
      return false;
    } catch (e) {
      print('Spend Coins Error: $e');
      return false;
    }
  }

  // Add with explicit source (for other modules e.g., voucher redemption)
  static Future<void> addCoinsWithSource(
    String username,
    int coins,
    String source,
  ) async {
    try {
      final currentCoins = await getCoins(username);
      final newCoins = currentCoins + coins;

      await _supabase
          .from(_tableName)
          .update({'coins': newCoins})
          .eq('username', username);

      print('Added $coins coins to user $username (source: $source)');
      await _logTransaction(
        username: username,
        amount: coins,
        type: 'add',
        source: source,
      );
    } catch (e) {
      print('Add Coins With Source Error: $e');
    }
  }

  // Spend with explicit source
  static Future<bool> spendCoinsWithSource(
    String username,
    int coins,
    String source,
  ) async {
    try {
      final currentCoins = await getCoins(username);
      if (currentCoins >= coins) {
        final newCoins = currentCoins - coins;
        await _supabase
            .from(_tableName)
            .update({'coins': newCoins})
            .eq('username', username);

        print('Spent $coins coins from user $username (source: $source)');
        await _logTransaction(
          username: username,
          amount: coins,
          type: 'spend',
          source: source,
        );
        return true;
      }
      print('Insufficient coins for user $username');
      return false;
    } catch (e) {
      print('Spend Coins With Source Error: $e');
      return false;
    }
  }

  // Set coins to a specific amount
  static Future<void> setCoins(String username, int coins) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'coins': coins})
          .eq('username', username);

      print('Set coins for user $username to $coins');
    } catch (e) {
      print('Set Coins Error: $e');
    }
  }

  // Initialize coins for new user (only called from UserService during registration)
  static Future<void> initializeCoins(int userId, String username) async {
    try {
      await _supabase.from(_tableName).insert({
        'user_id': userId,
        'username': username,
        'coins': 0,
      });

      print('Initialized coins for user $username');
    } catch (e) {
      print('Initialize Coins Error: $e');
    }
  }
}
