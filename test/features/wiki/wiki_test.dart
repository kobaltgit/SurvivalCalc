import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/features/wiki/data/wiki_repository.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_category.dart';
import 'package:survival_calc/features/wiki/presentation/providers/wiki_providers.dart';
import 'package:survival_calc/features/wiki/presentation/screens/wiki_article_detail_screen.dart';
import 'package:survival_calc/features/wiki/presentation/screens/wiki_screen.dart';
import 'package:survival_calc/features/wiki/presentation/widgets/wiki_markdown_viewer.dart';

void main() {
  group('WikiRepository Domain Tests', () {
    const repo = WikiRepository();

    test('getAllArticles returns non-empty list of articles', () {
      final articles = repo.getAllArticles();
      expect(articles.length, greaterThanOrEqualTo(7));
      expect(articles.any((a) => a.id == 'manual_pre_trip'), isTrue);
      expect(articles.any((a) => a.id == 'physiology_formulas'), isTrue);
    });

    test('All WikiCategory values have corresponding articles', () {
      for (final cat in WikiCategory.values) {
        final catArticles = repo.getArticlesByCategory(cat);
        expect(catArticles, isNotEmpty, reason: 'Category ${cat.title} has no articles');
      }
    });

    test('getArticleById returns correct article or null if not found', () {
      final article = repo.getArticleById('manual_pre_trip');
      expect(article, isNotNull);
      expect(article!.title, contains('Этап 1'));

      final missing = repo.getArticleById('non_existent_article_id');
      expect(missing, isNull);
    });

    test('searchArticles matches by title, tags, keywords and content', () {
      final bmrMatches = repo.searchArticles('BMR');
      expect(bmrMatches, isNotEmpty);
      expect(bmrMatches.any((a) => a.id == 'physiology_formulas'), isTrue);

      final qrMatches = repo.searchArticles('QR');
      expect(qrMatches, isNotEmpty);

      final mkkMatches = repo.searchArticles('МКК');
      expect(mkkMatches, isNotEmpty);

      final gasMatches = repo.searchArticles('газ');
      expect(gasMatches, isNotEmpty);
    });

    test('searchArticles filters by category when specified', () {
      final foodMatches = repo.searchArticles('', category: WikiCategory.food);
      expect(foodMatches.every((a) => a.category == WikiCategory.food), isTrue);
    });
  });

  group('Wiki UI Widget Tests', () {
    testWidgets('WikiMarkdownViewer renders headings, lists and callouts', (tester) async {
      const sampleMarkdown = '''
# Заголовок H1
## Заголовок H2
### Заголовок H3
---
> 💡 **Совет бывалого:** Держите телефон в тепле.
- Пункт списка 1
- Пункт списка 2
1. Первый шаг
2. Второй шаг
| Продукт | Калории |
| --- | --- |
| Сало | 816 ккал |
\$\$BMR = 10 \\times W\$\$
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WikiMarkdownViewer(markdown: sampleMarkdown),
            ),
          ),
        ),
      );

      expect(find.text('Заголовок H1'), findsOneWidget);
      expect(find.text('Заголовок H2'), findsOneWidget);
      expect(find.text('Заголовок H3'), findsOneWidget);
      expect(find.text('💡 Совет бывалого'), findsOneWidget);
      expect(find.text('Первый шаг'), findsOneWidget);
      expect(find.text('Сало'), findsOneWidget);
    });

    testWidgets('WikiScreen renders search bar and article cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WikiScreen(),
          ),
        ),
      );

      expect(find.text('База знаний'), findsWidgets);
      expect(find.text('Все разделы'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('100% OFFLINE'), findsOneWidget);
    });

    testWidgets('WikiArticleDetailScreen renders article content without missing words or tags', (tester) async {
      const repo = WikiRepository();
      final article = repo.getArticleById('manual_pre_trip')!;

      await tester.pumpWidget(
        MaterialApp(
          home: WikiArticleDetailScreen(article: article),
        ),
      );

      expect(find.text(article.title), findsWidgets);
      expect(find.text(article.subtitle), findsOneWidget);
      expect(find.text('Назад ко всем статьям'), findsOneWidget);

      // Verify that italic, bold and code terms are rendered properly
      expect(find.textContaining('Вегетарианство'), findsWidgets);
      expect(find.textContaining('Астма'), findsWidgets);
      expect(find.textContaining('nakarte.me'), findsWidgets);
      expect(find.textContaining('Shopping List'), findsWidgets);
      expect(find.textContaining('Крупы и супы'), findsWidgets);
    });

    testWidgets('All 11 Wiki articles render without exceptions in WikiMarkdownViewer', (tester) async {
      const repo = WikiRepository();
      for (final article in repo.getAllArticles()) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WikiMarkdownViewer(markdown: article.markdownContent),
              ),
            ),
          ),
        );
        expect(find.byType(WikiMarkdownViewer), findsOneWidget);
      }
    });
  });
}
