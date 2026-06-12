import 'dart:convert';
import 'package:http/http.dart' as http;

class AiSuggestion {
  final String description;
  final String? categoryName;
  final String? categoryIcon;

  AiSuggestion({
    required this.description,
    this.categoryName,
    this.categoryIcon,
  });
}

class OllamaService {
  static const String _baseUrl = 'https://ollama.cuong-labs.uk';
  static const String _model = 'gemma3:1b';

  static final List<String> _validIcons = [
    'folder', 'work', 'school', 'home', 'fitness', 'shopping',
    'music', 'book', 'code', 'language', 'trophy', 'flight',
    'pets', 'heart', 'star', 'person',
  ];

  /// Generate a description and category suggestion for a task title.
  static Future<AiSuggestion> suggest(String taskTitle) async {
    final prompt = '''You are a task assistant. Given a task title, output DESCRIPTION, CATEGORY and ICON.
Rules:
- Respond in the SAME LANGUAGE as the task title (Vietnamese or English).
- CATEGORY must be specific to the task content. Do NOT always say "Work". Pick the best fit.
- DESCRIPTION: 15-20 words, actionable.

Examples:
Task: "Learn React hooks" → DESCRIPTION: Study useState, useEffect and custom hooks through official React documentation and practice projects. CATEGORY: Programming ICON: code
Task: "Mua sữa và trứng" → DESCRIPTION: Đi siêu thị mua sữa tươi, trứng gà và các nhu yếu phẩm cần thiết cho tuần này. CATEGORY: Shopping ICON: shopping
Task: "Read Clean Code chapter 5" → DESCRIPTION: Read and take notes on chapter 5 about formatting and code readability best practices. CATEGORY: Reading ICON: book
Task: "Morning jog 30 min" → DESCRIPTION: Complete a 30-minute morning jog around the park to build cardio endurance and stay healthy. CATEGORY: Fitness ICON: fitness
Task: "Học từ vựng IELTS" → DESCRIPTION: Ôn tập và học thuộc 30 từ vựng IELTS theo chủ đề học thuật và công nghệ hôm nay. CATEGORY: English ICON: language
Task: "Fix login bug" → DESCRIPTION: Debug and fix the authentication error on the login page causing session timeout issues. CATEGORY: Programming ICON: code
Task: "Plan trip to Da Nang" → DESCRIPTION: Research flights, hotels and create a detailed itinerary for the upcoming Da Nang vacation. CATEGORY: Travel ICON: flight

Now respond for this task with EXACTLY 3 lines (no extra text):
DESCRIPTION: <your description>
CATEGORY: <specific category name>
ICON: <one of: folder, work, school, home, fitness, shopping, music, book, code, language, trophy, flight, pets, heart, star, person>

Task: "$taskTitle"''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return AiSuggestion(description: 'Không thể tạo mô tả. Vui lòng nhập thủ công.');
      }

      final data = jsonDecode(response.body);
      final text = (data['response'] as String?) ?? '';

      return _parse(text);
    } catch (e) {
      return AiSuggestion(description: 'Lỗi kết nối AI. Vui lòng nhập thủ công.');
    }
  }

  static AiSuggestion _parse(String text) {
    String description = '';
    String? categoryName;
    String? categoryIcon;

    // Extract DESCRIPTION line
    final descMatch = RegExp(r'DESCRIPTION:\s*(.+)', caseSensitive: false).firstMatch(text);
    if (descMatch != null) {
      description = descMatch.group(1)!.trim();
    }

    // Extract CATEGORY line — stop before ICON keyword if on same line
    final catMatch = RegExp(r'CATEGORY:\s*(.+?)(?:\s+ICON[:\s]|$)', caseSensitive: false).firstMatch(text);
    if (catMatch != null) {
      categoryName = catMatch.group(1)!.trim();
      // Clean up any trailing punctuation or extra text
      categoryName = categoryName.replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim();
      if (categoryName.isEmpty) categoryName = null;
    }

    // Extract ICON line
    final iconMatch = RegExp(r'ICON:\s*(\w+)', caseSensitive: false).firstMatch(text);
    if (iconMatch != null) {
      final icon = iconMatch.group(1)!.trim().toLowerCase();
      categoryIcon = _validIcons.contains(icon) ? icon : 'folder';
    }

    if (description.isEmpty) {
      description = 'Không thể tạo mô tả. Vui lòng nhập thủ công.';
    }

    return AiSuggestion(
      description: description,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
    );
  }
}
