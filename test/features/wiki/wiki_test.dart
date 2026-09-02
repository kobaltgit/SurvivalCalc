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

      final firstAidMatches = repo.searchArticles('гипогликемия');
      expect(firstAidMatches, isNotEmpty);
      expect(firstAidMatches.any((a) => a.id == 'first_aid_acute'), isTrue);

      final tourstileMatches = repo.searchArticles('турникет');
      expect(tourstileMatches, isNotEmpty);
      expect(tourstileMatches.any((a) => a.id == 'first_aid_trauma'), isTrue);

      final snakeMatches = repo.searchArticles('гадюка');
      expect(snakeMatches, isNotEmpty);
      expect(snakeMatches.any((a) => a.id == 'first_aid_bites'), isTrue);
    });

    test('searchArticles filters by category when specified', () {
      final foodMatches = repo.searchArticles('', category: WikiCategory.food);
      expect(foodMatches.every((a) => a.category == WikiCategory.food), isTrue);

      final firstAidCategoryMatches = repo.searchArticles('', category: WikiCategory.firstAid);
      expect(firstAidCategoryMatches.length, equals(5));
      expect(firstAidCategoryMatches.every((a) => a.category == WikiCategory.firstAid), isTrue);
    });
  });

  group('Wiki UI Widget Tests', () {
    testWidgets('WikiMarkdownViewer renders headings, lists and callouts', (tester) async {
      const sampleMarkdown = '''
# Заголовок H1
## Заголовок H2
### Заголовок H3
#### Заголовок H4
##### Заголовок H5
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
      expect(find.text('Заголовок H4'), findsOneWidget);
      expect(find.text('Заголовок H5'), findsOneWidget);
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

    testWidgets('First Aid article detail screen renders medical protocols', (tester) async {
      const repo = WikiRepository();
      final article = repo.getArticleById('first_aid_acute')!;

      await tester.pumpWidget(
        MaterialApp(
          home: WikiArticleDetailScreen(article: article),
        ),
      );

      expect(find.text(article.title), findsWidgets);
      expect(find.textContaining('Правило 15'), findsWidgets);
      expect(find.textContaining('Анафилактический шок'), findsWidgets);
      expect(find.textContaining('Острого живота'), findsWidgets);
    });

    testWidgets('All 15 Wiki articles render without exceptions in WikiMarkdownViewer', (tester) async {
      const repo = WikiRepository();
      final allArticles = repo.getAllArticles();
      expect(allArticles.length, equals(15));

      for (final article in allArticles) {
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
