import 'package:flutter/material.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_category.dart';

class WikiArticle {
  final String id;
  final String title;
  final String subtitle;
  final WikiCategory category;
  final IconData icon;
  final List<String> tags;
  final int readingTimeMinutes;
  final String markdownContent;
  final List<String> keywords;

  const WikiArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.tags,
    required this.readingTimeMinutes,
    required this.markdownContent,
    required this.keywords,
  });

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (title.toLowerCase().contains(q)) return true;
    if (subtitle.toLowerCase().contains(q)) return true;
    if (tags.any((t) => t.toLowerCase().contains(q))) return true;
    if (keywords.any((k) => k.toLowerCase().contains(q))) return true;
    if (markdownContent.toLowerCase().contains(q)) return true;
    return false;
  }
}
