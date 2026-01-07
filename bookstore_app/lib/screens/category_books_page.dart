import 'package:flutter/material.dart';

import '../models/book.dart';
import '../widgets/app_colors.dart';
import '../widgets/book_card.dart';
import '../widgets/top_message.dart';

class CategoryBooksPage extends StatefulWidget {
  const CategoryBooksPage({
    super.key,
    required this.category,
    required this.books,
    required this.favoriteIds,
    required this.onOpenBook,
    required this.onToggleFavorite,
  });

  final String category;
  final List<Book> books;
  final Set<int> favoriteIds;
  final ValueChanged<Book> onOpenBook;
  final Future<bool> Function(Book book) onToggleFavorite;

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

enum SortOption {
  none,
  priceAsc,
  priceDesc,
  ratingDesc,
  soldDesc,
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SortOption _sortOption = SortOption.none;

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

  Future<void> _handleFavorite(Book book) async {
    try {
      await widget.onToggleFavorite(book);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      showTopMessage(
        context,
        message: error.toString(),
        type: TopMessageType.error,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case SortOption.priceAsc:
        return 'Giá tăng';
      case SortOption.priceDesc:
        return 'Giá giảm';
      case SortOption.ratingDesc:
        return 'Đánh giá';
      case SortOption.soldDesc:
        return 'Bán chạy';
      default:
        return 'Sắp xếp';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sắp xếp theo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            _SortOptionTile(
              icon: Icons.attach_money,
              label: 'Giá tăng dần',
              isSelected: _sortOption == SortOption.priceAsc,
              onTap: () {
                setState(() => _sortOption = SortOption.priceAsc);
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              icon: Icons.money_off,
              label: 'Giá giảm dần',
              isSelected: _sortOption == SortOption.priceDesc,
              onTap: () {
                setState(() => _sortOption = SortOption.priceDesc);
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              icon: Icons.star_outline,
              label: 'Đánh giá cao nhất',
              isSelected: _sortOption == SortOption.ratingDesc,
              onTap: () {
                setState(() => _sortOption = SortOption.ratingDesc);
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              icon: Icons.local_fire_department_outlined,
              label: 'Bán chạy nhất',
              isSelected: _sortOption == SortOption.soldDesc,
              onTap: () {
                setState(() => _sortOption = SortOption.soldDesc);
                Navigator.pop(context);
              },
            ),
            if (_sortOption != SortOption.none)
              _SortOptionTile(
                icon: Icons.clear,
                label: 'Bỏ sắp xếp',
                isSelected: false,
                onTap: () {
                  setState(() => _sortOption = SortOption.none);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = _normalize(widget.category);
    final isAll = normalizedCategory == 'tat ca';
    var categoryBooks = widget.books.where((book) {
      if (isAll) return true;
      return _normalize(book.category) == normalizedCategory;
    }).where((book) {
      if (_query.isEmpty) return true;
      final term = _normalize(_query);
      return _normalize(book.title).contains(term) ||
          _normalize(book.author).contains(term);
    }).toList();

    // Helper to calculate final price after discount
    double getFinalPrice(Book book) {
      if (book.discount > 0) {
        return book.price * (1 - book.discount / 100);
      }
      return book.price;
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.priceAsc:
        categoryBooks.sort((a, b) => getFinalPrice(a).compareTo(getFinalPrice(b)));
        break;
      case SortOption.priceDesc:
        categoryBooks.sort((a, b) => getFinalPrice(b).compareTo(getFinalPrice(a)));
        break;
      case SortOption.ratingDesc:
        categoryBooks.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.soldDesc:
        categoryBooks.sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
        break;
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange600, AppColors.rose500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar và sort button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                // Search field - compact
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray200, width: 0.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _query = value.trim();
                        });
                      },
                      style: const TextStyle(fontSize: 13),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 10,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.gray400,
                                ),
                              ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort button
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _sortOption != SortOption.none
                          ? AppColors.orange50
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _sortOption != SortOption.none
                            ? AppColors.orange200
                            : AppColors.gray200,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort,
                          size: 16,
                          color: _sortOption != SortOption.none
                              ? AppColors.orange600
                              : AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSortLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _sortOption != SortOption.none
                                ? AppColors.orange600
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: _sortOption != SortOption.none
                              ? AppColors.orange600
                              : AppColors.gray500,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoryBooks.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có sách phù hợp.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.gray600),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: categoryBooks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final book = categoryBooks[index];
                      return BookCard(
                        book: book,
                        compact: true,
                        onTap: () => widget.onOpenBook(book),
                        isFavorite: widget.favoriteIds.contains(book.id),
                        onFavoriteTap: () => _handleFavorite(book),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.orange600 : AppColors.gray600,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.orange600 : AppColors.gray700,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check,
              color: AppColors.orange600,
              size: 20,
            )
          : null,
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
