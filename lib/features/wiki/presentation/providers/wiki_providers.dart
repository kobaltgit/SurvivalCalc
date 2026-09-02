import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/features/wiki/data/wiki_repository.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_article.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_category.dart';

final wikiRepositoryProvider = Provider<WikiRepository>((ref) {
  return const WikiRepository();
});

final wikiSearchQueryProvider = StateProvider<String>((ref) => '');

final wikiSelectedCategoryProvider = StateProvider<WikiCategory?>((ref) => null);

final filteredWikiArticlesProvider = Provider<List<WikiArticle>>((ref) {
  final repo = ref.watch(wikiRepositoryProvider);
  final query = ref.watch(wikiSearchQueryProvider);
  final category = ref.watch(wikiSelectedCategoryProvider);

  return repo.searchArticles(query, category: category);
});

final wikiArticleDetailProvider = Provider.family<WikiArticle?, String>((ref, id) {
  final repo = ref.watch(wikiRepositoryProvider);
  return repo.getArticleById(id);
});
