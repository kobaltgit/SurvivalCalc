import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_article.dart';
import 'package:survival_calc/features/wiki/presentation/widgets/wiki_markdown_viewer.dart';

class WikiArticleDetailScreen extends StatelessWidget {
  final WikiArticle article;

  const WikiArticleDetailScreen({
    super.key,
    required this.article,
  });

  static void navigate(BuildContext context, WikiArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WikiArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = article.category.color;

    return Scaffold(
      backgroundColor: OutdoorTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: OutdoorTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          article.category.title,
          style: TextStyle(
            color: catColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            tooltip: 'Поделиться статьей',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Статья «${article.title}» скопирована!'),
                  backgroundColor: OutdoorTheme.tacticalGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(article.category.icon, color: catColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        article.category.title.toUpperCase(),
                        style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('•', style: TextStyle(color: Colors.white38)),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded, color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readingTimeMinutes} мин чтения',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main Article Title
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  article.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Tags bar
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: article.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: OutdoorTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Markdown Content
                WikiMarkdownViewer(markdown: article.markdownContent),

                const SizedBox(height: 40),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                // Footer Back Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    label: const Text('Назад ко всем статьям', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OutdoorTheme.surfaceCard,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
