import 'package:flutter/material.dart';

import '../models/book.dart';
import '../widgets/app_colors.dart';
import '../widgets/book_card.dart';
import '../widgets/top_message.dart';

class BestSellerBooksPage extends StatefulWidget {
  const BestSellerBooksPage({
    super.key,
    required this.books,
    required this.favoriteIds,
    required this.onOpenBook,
    required this.onToggleFavorite,
  });

  final List<Book> books;
  final Set<int> favoriteIds;
  final ValueChanged<Book> onOpenBook;
  final Future<bool> Function(Book book) onToggleFavorite;

  @override
  State<BestSellerBooksPage> createState() => _BestSellerBooksPageState();
}

class _BestSellerBooksPageState extends State<BestSellerBooksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final bestSellerBooks = [...widget.books]
      ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));

    final filtered = bestSellerBooks.where((book) {
      if (_query.isEmpty) return true;
      final term = _normalize(_query);
      return _normalize(book.title).contains(term) ||
          _normalize(book.author).contains(term);
    }).toList();

    final top30 = filtered.take(30).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán chạy'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _query = value.trim();
                        });
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sách...',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: AppColors.gray600,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                  });
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 42,
                  width: 42,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.gray200),
                      backgroundColor: AppColors.gray100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune,
                      size: 20,
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: top30.isEmpty
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
                    itemCount: top30.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final book = top30[index];
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
