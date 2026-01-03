import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../widgets/app_colors.dart';
import '../widgets/book_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/header.dart';
import '../widgets/search_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.books, required this.onOpenBook});

  final List<Book> books;
  final ValueChanged<Book> onOpenBook;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _recentSearches = [];
  String _selectedCategory = 'Tất cả';
  static const int _maxRecentSearches = 8;
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    var output = input.toLowerCase();
    output = output.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    output = output.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    output = output.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    output = output.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    output = output.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    output = output.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    output = output.replaceAll(RegExp(r'đ'), 'd');
    output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
    return output;
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_recentSearchesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  void _addRecentSearch(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere(
        (item) => _normalize(item) == _normalize(text),
      );
      _recentSearches.insert(0, text);
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches.removeRange(
          _maxRecentSearches,
          _recentSearches.length,
        );
      }
    });
    _saveRecentSearches();
  }

  void _removeRecentSearch(String value) {
    setState(() {
      _recentSearches.remove(value);
    });
    _saveRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Tất cả',
      ...{for (final book in widget.books) book.category},
    ];
    final activeCategory =
        categories.contains(_selectedCategory) ? _selectedCategory : 'Tất cả';
    final query = _normalize(_controller.text.trim());

    final filtered = widget.books.where((book) {
      final titleMatch = _normalize(book.title).contains(query);
      final authorMatch = _normalize(book.author).contains(query);
      final categoryMatch = _normalize(activeCategory) == 'tat ca' ||
          _normalize(book.category) == _normalize(activeCategory);
      return (query.isEmpty || titleMatch || authorMatch) && categoryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: null,
              titleColor: Colors.white,
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconColor: Colors.white,
              showDivider: false,
              titleFlex: 0,
              middleFlex: 7,
              leadingSpacing: 0,
              middle: SearchBarField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                onSubmitted: _addRecentSearch,
                compact: true,
                height: 34,
                fillColor: Colors.white.withOpacity(0.18),
                iconColor: Colors.white,
                hintColor: Colors.white70,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (query.isEmpty && _recentSearches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tìm kiếm gần đây',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ..._recentSearches.map(
                            (search) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: 0,
                                vertical: -2,
                              ),
                              leading: const Icon(
                                Icons.history,
                                color: AppColors.gray600,
                                size: 18,
                              ),
                              title: Text(
                                search,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.gray700),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.gray600,
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _removeRecentSearch(search),
                              ),
                              onTap: () {
                                _controller.text = search;
                                _addRecentSearch(search);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return CategoryChip(
                              label: category,
                              isActive: activeCategory == category,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      query.isEmpty
                          ? 'Sách phổ biến'
                          : 'Kết quả (${filtered.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (query.isEmpty
                              ? widget.books.take(6).toList()
                              : filtered)
                          .length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final list =
                            query.isEmpty ? widget.books.take(6).toList() : filtered;
                        final book = list[index];
                        return BookCard(
                          book: book,
                          compact: true,
                          onTap: () => widget.onOpenBook(book),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
