import 'package:flutter/material.dart';

const Map<String, IconData> categoryIcons = {
  'folder': Icons.folder_outlined,
  'work': Icons.work_outlined,
  'school': Icons.school_outlined,
  'home': Icons.home_outlined,
  'fitness': Icons.fitness_center_outlined,
  'shopping': Icons.shopping_cart_outlined,
  'music': Icons.music_note_outlined,
  'book': Icons.book_outlined,
  'code': Icons.code_outlined,
  'language': Icons.language_outlined,
  'trophy': Icons.emoji_events_outlined,
  'flight': Icons.flight_outlined,
  'pets': Icons.pets_outlined,
  'heart': Icons.favorite_outlined,
  'star': Icons.star_outlined,
  'person': Icons.person_outlined,
};

IconData getIconData(String iconName) {
  return categoryIcons[iconName] ?? Icons.folder_outlined;
}
