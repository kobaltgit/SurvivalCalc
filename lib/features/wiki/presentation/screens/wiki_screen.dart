import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/wiki/domain/models/wiki_category.dart';
import 'package:survival_calc/features/wiki/presentation/providers/wiki_providers.dart';
import 'package:survival_calc/features/wiki/presentation/screens/wiki_article_detail_screen.dart';
import 'package:survival_calc/features/wiki/presentation/widgets/wiki_article_card.dart';

class WikiScreen extends ConsumerStatefulWidget {
  const WikiScreen({super.key});

  static void navigate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WikiScreen()),
    );
  }

  @override
  ConsumerState<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends ConsumerState<WikiScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(wikiSearchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(wikiSelectedCategoryProvider);
    final articles = ref.watch(filteredWikiArticlesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: OutdoorTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: OutdoorTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: OutdoorTheme.signalOrange, size: 22),
            SizedBox(width: 8),
            Text(
              'База знаний & Википедия',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OutdoorTheme.tacticalGreen),
            ),
            child: const Center(
              child: Text(
                '100% OFFLINE',
                style: TextStyle(
                  color: OutdoorTheme.tacticalGreen,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Search & Guide Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OutdoorTheme.surfaceCard,
                        const Color(0xFF1E3A2F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_stories_rounded, color: Colors.cyanAccent, size: 26),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Энциклопедия выживания и походного быта',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Полное руководство пользователя, физиологические формулы BMR/PAL, справочники калорийности и стандарты МКК.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (value) {
                          ref.read(wikiSearchQueryProvider.notifier).state = value;
                        },
                        decoration: InputDecoration(
                          hintText: 'Поиск по статьям, формулам и терминам (напр. газ, BMR, QR, МКК)...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: OutdoorTheme.signalOrange),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.white60),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(wikiSearchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: OutdoorTheme.darkBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: selectedCategory == null,
                          label: const Text('Все разделы'),
                          selectedColor: OutdoorTheme.signalOrange,
                          backgroundColor: OutdoorTheme.surfaceCard,
                          labelStyle: TextStyle(
                            color: selectedCategory == null ? Colors.black : Colors.white70,
                            fontWeight: selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                          onSelected: (_) {
                            ref.read(wikiSelectedCategoryProvider.notifier).state = null;
                          },
                        ),
                      ),
                      ...WikiCategory.values.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            avatar: Icon(cat.icon, color: isSelected ? Colors.black : cat.color, size: 16),
                            label: Text(cat.title),
                            selectedColor: cat.color,
                            backgroundColor: OutdoorTheme.surfaceCard,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            onSelected: (_) {
                              ref.read(wikiSelectedCategoryProvider.notifier).state = isSelected ? null : cat;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Articles count header
                Row(
                  children: [
                    Text(
                      selectedCategory != null ? selectedCategory.title : 'Статьи и материалы',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: OutdoorTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${articles.length}',
                        style: const TextStyle(
                          color: OutdoorTheme.signalOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Articles List / Grid
                if (articles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Colors.white38, size: 54),
                        const SizedBox(height: 16),
                        const Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Попробуйте изменить запрос или очистить фильтр категории.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(wikiSearchQueryProvider.notifier).state = '';
                            ref.read(wikiSelectedCategoryProvider.notifier).state = null;
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: OutdoorTheme.signalOrange),
                          ),
                          child: const Text('Сбросить фильтры', style: TextStyle(color: OutdoorTheme.signalOrange)),
                        ),
                      ],
                    ),
                  )
                else if (isDesktop)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 190,
                    ),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return WikiArticleCard(
                        article: article,
                        onTap: () => WikiArticleDetailScreen.navigate(context, article),
                      );
                    },
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return WikiArticleCard(
                        article: article,
                        onTap: () => WikiArticleDetailScreen.navigate(context, article),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
