# Hướng dẫn CRUD & Kết nối Supabase — TaskFlow

## 1. Kiến trúc tổng quan

```
main.dart → Khởi tạo Supabase + Provider
  ├─ AuthService        → Xác thực (SignUp, SignIn, SignOut)
  ├─ DatabaseService    → CRUD Tasks + Categories
  └─ Screens            → UI gọi service qua Provider (ChangeNotifier)
```

**Công nghệ:**
- Flutter + Dart
- `supabase_flutter: ^2.8.0` — client SDK
- `flutter_dotenv` — đọc biến môi trường
- `provider` — state management

---

## 2. Kết nối Supabase

### 2.1 Khởi tạo — `lib/main.dart`

```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'],
  publishableKey: dotenv.env['SUPABASE_ANON_KEY'],
);
```

### 2.2 File `.env`

```
SUPABASE_URL=https://hlwebzrcfuocpdplpcrm.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2.3 Các bảng trong Supabase

| Table | Mô tả | Khóa ngoại |
|-------|-------|-----------|
| `profiles` | Thông tin người dùng | `id` → auth.users |
| `categories` | Danh mục công việc | `user_id` → profiles.id |
| `tasks` | Công việc | `user_id` → profiles.id, `category_id` → categories.id |

---

## 3. CRUD — Tasks

Tất cả trong **`lib/services/database_service.dart`**.

### CREATE — `addTask(task)` (dòng 135)

```dart
final response = await _supabase
    .from('tasks')
    .insert(task.toJson())
    .select('*, categories(*)')
    .single();
```

- `.insert()` → thêm record
- `.select('*, categories(*)')` → trả về kèm dữ liệu category (Supabase join)
- `.single()` → mong đợi 1 dòng trả về

### READ — `fetchTasks(userId)` (dòng 110)

```dart
final response = await _supabase
    .from('tasks')
    .select('*, categories(*)')
    .eq('user_id', userId)
    .order('created_at', ascending: false);
```

- `.select('*, categories(*)')` → lấy tất cả cột + join categories
- `.eq('user_id', userId)` → lọc theo user
- `.order('created_at', ascending: false)` → sắp xếp mới nhất trước

### UPDATE — `updateTask(task)` (dòng 154)

```dart
final response = await _supabase
    .from('tasks')
    .update(task.toJson())
    .eq('id', task.id)
    .select('*, categories(*)')
    .single();
```

### UPDATE (toggle) — `toggleTask(id, isCompleted)` (dòng 174)

```dart
await _supabase
    .from('tasks')
    .update({'is_completed': isCompleted})
    .eq('id', id);
```

### DELETE — `deleteTask(id)` (dòng 192)

```dart
await _supabase.from('tasks').delete().eq('id', id);
```

---

## 4. CRUD — Categories

Cùng file **`lib/services/database_service.dart`**.

### CREATE — `addCategory(category)` (dòng 56)

```dart
final response = await _supabase
    .from('categories')
    .insert(category.toJson())
    .select()
    .single();
```

### READ — `fetchCategories(userId)` (dòng 31)

```dart
final response = await _supabase
    .from('categories')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: true);
```

### UPDATE — `updateCategory(category)` (dòng 74)

```dart
await _supabase
    .from('categories')
    .update(category.toJson())
    .eq('id', category.id);
```

### DELETE — `deleteCategory(id)` (dòng 92)

```dart
await _supabase.from('categories').delete().eq('id', id);
```

Khi xóa category, code cũng clear `category_id` ở các task liên quan (dòng 96-99):

```dart
for (var i = 0; i < _tasks.length; i++) {
  if (_tasks[i].categoryId == id) {
    _tasks[i] = _tasks[i].copyWith(categoryId: null, category: null);
  }
}
```

---

## 5. Authentication — `lib/services/auth_service.dart`

| Chức năng            | Method Supabase                                                 |
|----------------------|-----------------------------------------------------------------|
| Đăng ký              | `_supabase.auth.signUp(email:, password:, data:)`               |
| Đăng nhập            | `_supabase.auth.signInWithPassword(email:, password:)`          |
| Đăng xuất            | `_supabase.auth.signOut()`                                      |
| Lấy profile          | `_supabase.from('profiles').select().eq('id', userId).single()` |
| Cập nhật profile     | `_supabase.from('profiles').update(updates).eq('id', id)`       |
| Lắng nghe auth state | `_supabase.auth.onAuthStateChange.listen(...)`                  |

---

## 6. Models (Dart → Supabase mapping)

### TaskModel — `lib/models/task_model.dart`

```dart
// Dart field       → Supabase column
// id               → id
// userId           → user_id
// categoryId       → category_id
// title            → title
// description      → description
// isCompleted      → is_completed
// priority         → priority (1=Thấp, 2=TB, 3=Cao)
// dueDate          → due_date
// createdAt        → created_at
// updatedAt        → updated_at
// category         → categories (join object)
```

### CategoryModel — `lib/models/category_model.dart`

```dart
// Dart field       → Supabase column
// id               → id
// userId           → user_id
// name             → name
// color            → color (#HEX)
// icon             → icon
// createdAt        → created_at
```

### UserModel — `lib/models/user_model.dart`

```dart
// Dart field       → Supabase column (table profiles)
// id               → id
// email            → email
// fullName         → full_name
// avatarUrl        → avatar_url
// createdAt        → created_at
```

---

## 7. Luồng hoạt động (ví dụ: Thêm task)

```
User điền form → nhấn "Thêm"
  → AddEditTaskScreen._save() [lib/screens/add_edit_task_screen.dart:64]
    → Tạo TaskModel
    → DatabaseService.addTask(task) [lib/services/database_service.dart:135]
      → Gọi Supabase insert
      → Nhận response có join category
      → Thêm vào list _tasks local
      → notifyListeners()
      → Provider rebuild HomeScreen → UI hiển thị task mới
```

---

## 8. State Management với Provider

- `DatabaseService` extends `ChangeNotifier`
- Mỗi CRUD đều gọi `notifyListeners()` sau khi cập nhật local state
- `HomeScreen` dùng `context.watch<DatabaseService>()` để lắng nghe thay đổi
- Khi data thay đổi, UI tự động rebuild

### Reset khi logout

```dart
// database_service.dart:18
_supabase.auth.onAuthStateChange.listen((authState) {
  if (authState.session == null) reset();
});
```

---

## 9. Tổng kết

| Thành phần       | File chính                             | Dòng code CRUD          |
|------------------|----------------------------------------|-------------------------|
| Kết nối Supabase | `lib/main.dart`                        | 14-17                   |
| Auth             | `lib/services/auth_service.dart`       | Toàn bộ file (135 dòng) |
| CRUD Tasks       | `lib/services/database_service.dart`   | 110-201                 |
| CRUD Categories  | `lib/services/database_service.dart`   | 31-106                  |
| Task Model       | `lib/models/task_model.dart`           | 108 dòng                |
| Category Model   | `lib/models/category_model.dart`       | 41 dòng                 |
| User Model       | `lib/models/user_model.dart`           | 36 dòng                 |
| UI Task          | `lib/screens/home_screen.dart`         | Gọi CRUD qua Provider   |
| UI Add/Edit      | `lib/screens/add_edit_task_screen.dart`| Gọi addTask/updateTask  |
| UI Category      | `lib/screens/category_screen.dart`     | Gọi CRUD category       |
| UI Profile       | `lib/screens/profile_screen.dart`      | Gọi updateProfile       |
