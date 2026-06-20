# Sqflite Favorites Demo

This project uses Sqflite to demonstrate a local database feature without Supabase. Supabase still stores the main task data, while Sqflite stores the user's favorite task list locally on the device.

## Feature

The demo feature is **Favorite Tasks**.

User flow:

1. User opens the task list.
2. User taps the heart icon on a task.
3. App saves a snapshot of that task into local SQLite.
4. User opens the Favorites screen from the heart icon in the home header.
5. Favorite tasks are loaded from SQLite and shown even after app restart.

This is useful for demo because it clearly shows:

- Flutter app can connect to another database layer.
- Local data persists without Supabase.
- Sqflite can insert, query, delete, and update UI state.

## Dependencies

Sqflite is added in `pubspec.yaml`:

```yaml
dependencies:
  sqflite: ^2.4.3
  path: ^1.9.1
```

`sqflite` provides SQLite database access.

`path` is used to build a safe database file path:

```dart
final dbPath = await getDatabasesPath();
final path = join(dbPath, 'taskflow_favorites.db');
```

## Main Files

| File | Purpose |
| --- | --- |
| `lib/services/favorite_service.dart` | Opens SQLite, creates table, handles favorite CRUD |
| `lib/screens/favorites_screen.dart` | UI screen showing favorite tasks from SQLite |
| `lib/screens/home_screen.dart` | Heart button on each task and Favorites shortcut |
| `lib/screens/task_detail_screen.dart` | Heart button in task detail |
| `lib/main.dart` | Registers `FavoriteService` with Provider |

## Database File

The SQLite database name is:

```text
taskflow_favorites.db
```

It is created by `FavoriteService` in:

```dart
static const _databaseName = 'taskflow_favorites.db';
```

Sqflite stores this file in the platform database directory returned by:

```dart
getDatabasesPath()
```

On Android, this is inside the app's private storage, so other apps cannot directly access it.

## Table Schema

The table name is:

```text
favorites
```

Schema:

```sql
CREATE TABLE favorites (
  task_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER NOT NULL,
  due_date TEXT,
  created_at TEXT NOT NULL
);
```

Column meaning:

| Column | Type | Meaning |
| --- | --- | --- |
| `task_id` | `TEXT PRIMARY KEY` | Supabase task id, used as unique favorite id |
| `title` | `TEXT NOT NULL` | Task title snapshot |
| `description` | `TEXT` | Task description snapshot |
| `priority` | `INTEGER NOT NULL` | Task priority: 1 low, 2 medium, 3 high |
| `due_date` | `TEXT` | ISO date string, nullable |
| `created_at` | `TEXT NOT NULL` | When the task was favorited locally |

The app stores a **snapshot** instead of only storing `task_id`. This makes the Favorites screen still able to show useful data even if the task list has not loaded yet.

## Service Flow

All SQLite logic lives in:

```text
lib/services/favorite_service.dart
```

### 1. Open Database

`FavoriteService` lazily opens the database:

```dart
Future<Database> get _db async {
  if (_database != null) return _database!;

  final dbPath = await getDatabasesPath();
  final path = join(dbPath, _databaseName);

  _database = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE ...');
    },
  );

  return _database!;
}
```

The table is created only the first time the database is created.

### 2. Load Favorites

On app startup, `main.dart` registers and loads the service:

```dart
ChangeNotifierProvider(
  create: (_) => FavoriteService()..loadFavorites(),
),
```

`loadFavorites()` reads rows from SQLite:

```dart
final rows = await db.query(_tableName, orderBy: 'created_at DESC');
```

Then it stores them in memory:

```dart
final Map<String, FavoriteItem> _favorites = {};
```

This map makes `isFavorite(taskId)` fast for UI checks.

### 3. Add Favorite

When the user taps an empty heart icon:

```dart
await favorites.toggleFavorite(task);
```

The service converts `TaskModel` to `FavoriteItem`, then inserts it:

```dart
await db.insert(
  _tableName,
  item.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

`ConflictAlgorithm.replace` means tapping favorite again after task updates can refresh the local snapshot safely.

### 4. Remove Favorite

When the user taps a filled heart icon:

```dart
await db.delete(
  _tableName,
  where: 'task_id = ?',
  whereArgs: [taskId],
);
```

The service also removes the item from the in-memory map and calls:

```dart
notifyListeners();
```

That updates Home and Favorites screen automatically.

## UI Integration

### Home Screen

`home_screen.dart` reads the service:

```dart
final favorites = context.watch<FavoriteService>();
```

Each task card checks:

```dart
final isFavorite = favorites.isFavorite(task.id);
```

Then it shows:

- `Icons.favorite_border_rounded` if not favorite
- `Icons.favorite_rounded` if favorite

The home header also shows a heart shortcut with a badge count:

```dart
favorites.count
```

Tapping the shortcut opens:

```dart
FavoritesScreen()
```

### Task Detail Screen

`task_detail_screen.dart` has the same favorite toggle in the app bar.

This lets user favorite from either:

- task list
- task detail

### Favorites Screen

`favorites_screen.dart` shows:

- a top banner saying data is stored in SQLite
- favorite task cards
- remove favorite button
- empty state when no favorites exist

It combines Supabase task data with local SQLite state:

```dart
final favoriteTasks = db.tasks
    .where((task) => favorites.isFavorite(task.id))
    .toList();
```

If Supabase tasks are not loaded, it can still show the local SQLite snapshots from:

```dart
favorites.favorites
```

## Demo Script

Use this flow for presentation:

1. Open app and login.
2. Create or pick a task.
3. Tap the heart icon on the task card.
4. Open the Favorites screen from the heart icon in the header.
5. Explain that this data comes from local SQLite table `favorites`.
6. Close and reopen the app.
7. Open Favorites again and show the task still exists.
8. Tap the filled heart or remove button to delete it from SQLite.

## Why This Is Not Supabase

Supabase is still used for core task/category data.

Sqflite is used for local-only favorites:

```text
Task CRUD        -> Supabase
Favorite status  -> Sqflite local SQLite
```

This keeps the demo small and easy to understand. It also shows a realistic pattern: remote database for main data, local database for fast user-specific state.

## Notes

- The current schema version is `1`.
- If the schema changes later, increase `version` in `openDatabase()` and add `onUpgrade`.
- The SQLite favorite stores a task snapshot, not a full task relation.
- Deleting a task also removes its favorite entry from SQLite in the current UI flow.
