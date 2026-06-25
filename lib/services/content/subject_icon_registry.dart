import 'package:flutter/material.dart';

class SubjectIconRegistry {
  static const _icons = <String, IconData>{
    'calculate_outlined': Icons.calculate_outlined,
    'biotech_outlined': Icons.biotech_outlined,
    'public_outlined': Icons.public_outlined,
    'menu_book_outlined': Icons.menu_book_outlined,
    'science_outlined': Icons.science_outlined,
    'category_outlined': Icons.category_outlined,
    'flag_outlined': Icons.flag_outlined,
  };

  static IconData iconFor(String iconKey) =>
      _icons[iconKey] ?? Icons.school_outlined;

  static Color colorFromHex(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}
