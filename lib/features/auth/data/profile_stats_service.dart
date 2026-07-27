import '../../../core/database/database_helper.dart';

/// Real numbers for the profile header — replaces two stats that used to be
/// fabricated: "places visited" was `tripCount * 0.7` (never an actual count),
/// and the third stat was a static "AI 🤖" label with no number behind it at
/// all.
///
/// Not filtered by the signed-in user's uid: this app is local-first and
/// every other trip query (`getAllTrips`, etc.) already reads the whole local
/// database unfiltered, so scoping only these two counts to `user_id` would
/// make them inconsistent with the trip count shown right next to them.
class ProfileStatsService {
  final DatabaseHelper _dbHelper;

  ProfileStatsService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Stops the user has actually marked as visited, across every trip.
  Future<int> visitedPlacesCount() async {
    final rows = await _dbHelper.query(
      'stops',
      where: 'is_visited = 1',
    );
    return rows.length;
  }

  /// Messages the user has sent to the AI assistant, across every trip's chat.
  Future<int> messagesSentCount() async {
    final rows = await _dbHelper.query(
      'chat_messages',
      where: "role = 'user'",
    );
    return rows.length;
  }
}
