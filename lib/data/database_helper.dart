import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/movie.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 5, // ✅ Tăng phiên bản lên 5 để kích hoạt onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        overview TEXT,
        poster_path TEXT,
        vote_average REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER,
        category TEXT,
        title TEXT,
        body TEXT,
        poster_path TEXT,
        payload TEXT,
        genre_ids TEXT,
        timestamp TEXT,
        is_read INTEGER DEFAULT 0,
        UNIQUE(movie_id, category)
      )
    ''');
  }

  // Hàm này sẽ được gọi khi phiên bản DB tăng lên
  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Nếu phiên bản cũ không có bảng app_notifications, hãy tạo nó
      // Hoặc đơn giản là xóa bảng cũ và tạo lại
      await db.execute("DROP TABLE IF EXISTS favorites");
      await db.execute("DROP TABLE IF EXISTS app_notifications");
      _onCreate(db, newVersion);
    }
  }

  Future<List<Movie>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) {
      return Movie.fromDbMap(maps[i]);
    });
  }

  Future<void> insertFavorite(Movie movie) async {
    final db = await database;
    await db.insert('favorites', movie.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFavorite(int id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // --- Các hàm cho Notification ---

  Future<int> insertAppNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('app_notifications', notification,
        conflictAlgorithm: ConflictAlgorithm
            .ignore); // Dùng ignore, sẽ trả về 0 nếu đã tồn tại
  }

  Future<List<Map<String, dynamic>>> getAppNotifications() async {
    final db = await database;
    // Sắp xếp để thông báo mới nhất lên đầu
    return await db.query('app_notifications', orderBy: 'timestamp DESC');
  }

  // Lấy thông báo ứng dụng với phân trang và theo category
  Future<List<Map<String, dynamic>>> getNotificationsByCategory(String category,
      {int limit = 20, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'app_notifications',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> deleteAllNotifications() async {
    final db = await database;
    await db.delete('app_notifications');
  }

  Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete('app_notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) FROM app_notifications WHERE is_read = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Lấy ra các genre ID người dùng yêu thích nhất
  Future<List<int>> getTopFavoriteGenres() async {
    // Đây là một phiên bản giả lập. Trong thực tế, bạn sẽ cần logic phức tạp hơn
    // để phân tích các phim trong bảng 'favorites'.
    // Giả sử người dùng thích thể loại Hành động (28) và Khoa học viễn tưởng (878).
    return [28, 878];
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
