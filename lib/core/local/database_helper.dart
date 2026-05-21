class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<void> get database async {}

  Future<List<Map<String, dynamic>>> getFeedLogs(String farmId) async => [];

  Future<void> insertFeedLog(Map<String, dynamic> row) async {}

  Future<double> getTotalFeedCost(String farmId) async => 0.0;
}
