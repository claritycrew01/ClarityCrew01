import 'package:flutter/material.dart';

class SubjectData {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> chapters;
  final int lessonCount;
  final int videoCount;

  const SubjectData({
    required this.name,
    required this.icon,
    required this.color,
    required this.chapters,
    required this.lessonCount,
    required this.videoCount,
  });
}
