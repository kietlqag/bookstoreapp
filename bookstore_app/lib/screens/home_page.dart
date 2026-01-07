import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/book.dart';
import '../models/cart_item.dart';
import '../models/category_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/book_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/floating_chat.dart';
import '../widgets/header.dart';
import '../widgets/price_formatter.dart';
import '../widgets/search_bar.dart';
import '../widgets/top_message.dart';
import 'cart_page.dart';
import 'category_books_page.dart';
import 'contact_page.dart';
import 'best_seller_books_page.dart';
import 'featured_books_page.dart';
import 'favorites_page.dart';
import 'notification_list_page.dart';
import 'profile_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.books,
    required this.cartItems,
    required this.favoriteIds,
    required this.categoryService,
    required this.onOpenBook,
    required this.onIncreaseCart,
    required this.onDecreaseCart,
    required this.onRemoveCart,
    required this.onOrderCompleted,
    required this.onToggleFavorite,
    required this.onLogout,
    required this.userId,
  });

  static final ValueNotifier<String> tabNotifier =
      ValueNotifier<String>('home');

  static void setActiveTab(String tab) {
    tabNotifier.value = tab;
  }

  final List<Book> books;
  final List<CartItem> cartItems;
  final Set<int> favoriteIds;
  final CategoryService categoryService;
  final ValueChanged<Book> onOpenBook;
  final ValueChanged<CartItem> onIncreaseCart;
  final ValueChanged<CartItem> onDecreaseCart;
  final ValueChanged<CartItem> onRemoveCart;
  final ValueChanged<List<int>> onOrderCompleted;
  final Future<bool> Function(Book book) onToggleFavorite;
  final VoidCallback onLogout;
  final int userId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activeTab = 'home';
  late final VoidCallback _tabListener;

  void _handleTabChange(String tab) {
    if (HomePage.tabNotifier.value != tab) {
      HomePage.tabNotifier.value = tab;
    }
    setState(() {
      _activeTab = tab;
    });
  }

  @override
  void initState() {
    super.initState();
    _activeTab = HomePage.tabNotifier.value;
    _tabListener = () {
      final next = HomePage.tabNotifier.value;
      if (!mounted || next == _activeTab) return;
      setState(() {
        _activeTab = next;
      });
    };
    HomePage.tabNotifier.addListener(_tabListener);
  }

  @override
  void dispose() {
    HomePage.tabNotifier.removeListener(_tabListener);
    super.dispose();
  }

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.4:8080';
    }
    return 'http://localhost:8080';
  }

  @override
  Widget build(BuildContext context) {
    final pages = {
      'home': _HomeTab(
        books: widget.books,
        favoriteIds: widget.favoriteIds,
        categoryService: widget.categoryService,
        onOpenBook: widget.onOpenBook,
        onOpenSearch: () => _handleTabChange('search'),
        onToggleFavorite: widget.onToggleFavorite,
      ),
      'search': SearchPage(
        books: widget.books,
        favoriteIds: widget.favoriteIds,
        onOpenBook: widget.onOpenBook,
        onToggleFavorite: widget.onToggleFavorite,
      ),
      'cart': CartPage(
        cartItems: widget.cartItems,
        onIncrease: widget.onIncreaseCart,
        onDecrease: widget.onDecreaseCart,
        onRemove: widget.onRemoveCart,
        onOpenBook: widget.onOpenBook,
        onOrderCompleted: widget.onOrderCompleted,
        userId: widget.userId,
      ),
      'contact': ContactPage(userId: widget.userId),
      'profile': ProfilePage(
        onLogout: widget.onLogout,
        userId: widget.userId,
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: pages.keys.toList().indexOf(_activeTab),
              children: pages.values.toList(),
            ),
          ),
          // Floating Chat Widget
          FloatingChatWidget(
            baseUrl: _resolveBaseUrl(),
            onOpenBook: widget.onOpenBook,
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        activeTab: _activeTab,
        onTabSelected: _handleTabChange,
        cartCount: widget.cartItems.length,
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.books,
    required this.favoriteIds,
    required this.categoryService,
    required this.onOpenBook,
    required this.onOpenSearch,
    required this.onToggleFavorite,
  });

  final List<Book> books;
  final Set<int> favoriteIds;
  final CategoryService categoryService;
  final ValueChanged<Book> onOpenBook;
  final VoidCallback onOpenSearch;
  final Future<bool> Function(Book book) onToggleFavorite;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categories = const ['Tất cả'];
  String _selectedCategory = '';
  final PageController _flashController =
      PageController(viewportFraction: 0.9);
  int _flashIndex = 0;
  late final DateTime _flashEndsAt;
  Timer? _flashTimer;
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration();

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

  void _openFeaturedPage() {
    final featuredByRating = [...widget.books]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final topFeaturedBooks = featuredByRating.take(30).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeaturedBooksPage(
          books: topFeaturedBooks,
          favoriteIds: widget.favoriteIds,
          onOpenBook: widget.onOpenBook,
          onToggleFavorite: widget.onToggleFavorite,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _flashEndsAt = DateTime.now().add(const Duration(hours: 5, minutes: 30));
    _timeLeft = _flashEndsAt.difference(DateTime.now());
    _flashTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final count = widget.books.length < 4 ? widget.books.length : 4;
      if (count <= 1 || !_flashController.hasClients) return;
      final next = (_flashIndex + 1) % count;
      _flashController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _flashEndsAt.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _timeLeft = remaining.isNegative ? Duration.zero : remaining;
      });
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.categoryService.fetchCategories();
      final names = categories
          .map((category) => category.name.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _categories = ['Tất cả', ...names];
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = '';
        }
      });
    } catch (_) {
      // Keep local defaults when the backend is unavailable.
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _flashController.dispose();

    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredByRating = [...widget.books]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final featuredBooks = featuredByRating.take(5).toList();
    final bestSellerBooks = [...widget.books]
      ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
    final bestSellerTop5 = bestSellerBooks.take(5).toList();
    final flashBooks = widget.books.take(4).toList();

    return Column(
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
          favoriteCount: widget.favoriteIds.length,
          titleFlex: 0,
          middleFlex: 7,
          leadingSpacing: 0,
          middle: SearchBarField(
            controller: _searchController,
            readOnly: true,
            onTap: widget.onOpenSearch,
            compact: true,
            height: 34,
            fillColor: Colors.white.withOpacity(0.18),
            iconColor: Colors.white,
            hintColor: Colors.white70,
          ),
          onFavoriteTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FavoritesPage(
                  books: widget.books,
                  favoriteIds: widget.favoriteIds,
                  onOpenBook: widget.onOpenBook,
                  onToggleFavorite: widget.onToggleFavorite,
                ),
              ),
            );
          },
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationListPage(),
              ),
            );
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FlashHeader(timeLeft: _timeLeft),
              ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _flashController,
            itemCount: flashBooks.length,
            onPageChanged: (index) {
              setState(() {
                _flashIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final book = flashBooks[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _FlashCard(
                  book: book,
                  onTap: () => widget.onOpenBook(book),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(flashBooks.length, (index) {
            final isActive = index == _flashIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.orange600 : AppColors.gray200,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: AppColors.orange600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
              Text(
                'Danh mục',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryChip(
                      label: category,
                      isActive: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryBooksPage(
                              category: category,
                              books: widget.books,
                              favoriteIds: widget.favoriteIds,
                              onOpenBook: widget.onOpenBook,
                              onToggleFavorite: widget.onToggleFavorite,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _categories.length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Nổi bật',
          icon: Icons.auto_awesome,
          onViewAll: _openFeaturedPage,
        ),
        SizedBox(
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final book = featuredBooks[index];
                      return SizedBox(
                        width: 150,
                        child: BookCard(
                          book: book,
                          compact: true,
                          onTap: () => widget.onOpenBook(book),
                          isFavorite: widget.favoriteIds.contains(book.id),
                          onFavoriteTap: () => _handleFavorite(book),
                        ),
                      );
                    },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: featuredBooks.length,
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Bán chạy',
          icon: Icons.trending_up,
          onViewAll: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BestSellerBooksPage(
                  books: widget.books,
                  favoriteIds: widget.favoriteIds,
                  onOpenBook: widget.onOpenBook,
                  onToggleFavorite: widget.onToggleFavorite,
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final book = bestSellerTop5[index];
                      return SizedBox(
                        width: 150,
                        child: BookCard(
                          book: book,
                          compact: true,
                          onTap: () => widget.onOpenBook(book),
                          isFavorite: widget.favoriteIds.contains(book.id),
                          onFavoriteTap: () => _handleFavorite(book),
                        ),
                      );
                    },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: bestSellerTop5.length,
          ),
        ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orange600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }
}



class _FlashHeader extends StatelessWidget {
  const _FlashHeader({required this.timeLeft});

  final Duration timeLeft;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hours = _twoDigits(timeLeft.inHours);
    final minutes = _twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = _twoDigits(timeLeft.inSeconds.remainder(60));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.orange600),
            const SizedBox(width: 6),
            Text(
              'Flash sale',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Row(
          children: [
            _TimeChip(value: hours),
            const SizedBox(width: 4),
            const Text(':'),
            const SizedBox(width: 4),
            _TimeChip(value: minutes),
            const SizedBox(width: 4),
            const Text(':'),
            const SizedBox(width: 4),
            _TimeChip(value: seconds),
          ],
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFE4E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  book.cover,
                  width: 110,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    color: AppColors.gray100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.gray600,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Flash sale',
                        style: TextStyle(
                          color: AppColors.orange600,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.rose500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPrice(book.price),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: AppColors.orange600,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
