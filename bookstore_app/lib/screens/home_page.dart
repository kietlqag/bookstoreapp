import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/book.dart';
import '../models/cart_item.dart';
import '../models/category_service.dart';
import '../models/notification_service.dart';
import '../models/flash_sale_service.dart';
import '../models/flash_sale.dart';
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
    required this.token,
    this.onReloadBooks,
  });

  static final ValueNotifier<String> tabNotifier =
      ValueNotifier<String>('home');

  static void setActiveTab(String tab) {
    tabNotifier.value = tab;
  }

  final List<Book> books;
  final VoidCallback? onReloadBooks;
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
  final String token;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activeTab = 'home';
  late final VoidCallback _tabListener;
  final ValueNotifier<bool> _profileReloadNotifier = ValueNotifier<bool>(false);
  String? _previousTab;

  void _handleTabChange(String tab) {
    if (HomePage.tabNotifier.value != tab) {
      HomePage.tabNotifier.value = tab;
    }
    setState(() {
      _previousTab = _activeTab;
      _activeTab = tab;
    });
    // Reload profile page when switching to profile tab
    if (tab == 'profile') {
      _profileReloadNotifier.value = !_profileReloadNotifier.value;
    }
    // Reload books when switching to home tab to update rating and soldQuantity
    if (tab == 'home') {
      widget.onReloadBooks?.call();
    }
  }
  
  void _handleOrderCompleted(List<int> cartItemIds) {
    widget.onOrderCompleted(cartItemIds);
    // Reload profile page if it's the current tab to update stats
    if (_activeTab == 'profile') {
      _profileReloadNotifier.value = !_profileReloadNotifier.value;
    }
    // Always reload books after order to update soldQuantity
    widget.onReloadBooks?.call();
  }

  @override
  void initState() {
    super.initState();
    _activeTab = HomePage.tabNotifier.value;
    _tabListener = () {
      final next = HomePage.tabNotifier.value;
      if (!mounted || next == _activeTab) return;
      setState(() {
        _previousTab = _activeTab;
        _activeTab = next;
      });
      // Reload profile page when switching to profile tab
      if (next == 'profile') {
        _profileReloadNotifier.value = !_profileReloadNotifier.value;
      }
      // Reload books when switching to home tab
      if (next == 'home') {
        widget.onReloadBooks?.call();
      }
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
      return 'http://192.168.1.155:8080';
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
        baseUrl: _resolveBaseUrl(),
        token: widget.token,
        userId: widget.userId,
      ),
      'search': SearchPage(
        books: widget.books,
        favoriteIds: widget.favoriteIds,
        onOpenBook: widget.onOpenBook,
        onToggleFavorite: widget.onToggleFavorite,
        baseUrl: _resolveBaseUrl(),
        token: widget.token,
        userId: widget.userId,
      ),
      'cart': CartPage(
        cartItems: widget.cartItems,
        onIncrease: widget.onIncreaseCart,
        onDecrease: widget.onDecreaseCart,
        onRemove: widget.onRemoveCart,
        onOpenBook: widget.onOpenBook,
        onOrderCompleted: _handleOrderCompleted,
        userId: widget.userId,
      ),
      'contact': ContactPage(userId: widget.userId, token: widget.token),
      'profile': ProfilePage(
        onLogout: widget.onLogout,
        userId: widget.userId,
        token: widget.token,
        reloadNotifier: _profileReloadNotifier,
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
    required this.baseUrl,
    required this.token,
    required this.userId,
  });

  final List<Book> books;
  final Set<int> favoriteIds;
  final CategoryService categoryService;
  final ValueChanged<Book> onOpenBook;
  final VoidCallback onOpenSearch;
  final Future<bool> Function(Book book) onToggleFavorite;
  final String baseUrl;
  final String token;
  final int userId;

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
  late final NotificationService _notificationService =
      NotificationService(baseUrl: widget.baseUrl, token: widget.token);
  late final FlashSaleService _flashSaleService = FlashSaleService(baseUrl: widget.baseUrl);
  int _unreadNotificationCount = 0;
  List<Book> _currentBooks = [];
  FlashSale? _activeFlashSale;
  List<Book> _flashSaleBooks = [];

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always update books when widget.books reference changes
    // This ensures UI updates when books are reloaded from DB
    if (oldWidget.books != widget.books) {
      setState(() {
        _currentBooks = List<Book>.from(widget.books);
      });
      return;
    }
    
    // Even if reference is same, check if any book properties changed
    // This handles cases where books list is recreated but properties updated
    if (oldWidget.books.length != widget.books.length) {
      setState(() {
        _currentBooks = List<Book>.from(widget.books);
      });
      return;
    }
    
    // Deep check for property changes (rating, soldQuantity, reviewCount)
    bool hasChanges = false;
    for (int i = 0; i < widget.books.length && i < oldWidget.books.length; i++) {
      final oldBook = oldWidget.books[i];
      final newBook = widget.books[i];
      if (oldBook.id != newBook.id ||
          oldBook.rating != newBook.rating ||
          oldBook.soldQuantity != newBook.soldQuantity ||
          oldBook.reviewCount != newBook.reviewCount) {
        hasChanges = true;
        break;
      }
    }
    if (hasChanges) {
      setState(() {
        _currentBooks = List<Book>.from(widget.books);
      });
    }
  }
  

  Future<void> _handleFavorite(Book book) async {
    try {
      await widget.onToggleFavorite(book);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      showTopMessage(
        context,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    }
  }

  void _openFeaturedPage() {
    final featuredByRating = [..._currentBooks]
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
    _currentBooks = widget.books;
    _loadCategories();
    _loadUnreadNotificationCount();
    _loadFlashSale();
  }

  Future<void> _loadFlashSale() async {
    try {
      final flashSale = await _flashSaleService.getActiveFlashSale();
      if (!mounted) return;
      
      debugPrint('[HomePage] Flash sale loaded: ${flashSale != null}');
      if (flashSale != null) {
        debugPrint('[HomePage] Flash sale ID: ${flashSale.id}, name: ${flashSale.name}');
        debugPrint('[HomePage] Flash sale startAt: ${flashSale.startAt}, endAt: ${flashSale.endAt}');
        debugPrint('[HomePage] Flash sale books count: ${flashSale.books.length}');
        debugPrint('[HomePage] Flash sale isActive: ${flashSale.isActive}');
        debugPrint('[HomePage] Current time: ${DateTime.now()}');
      }
      
      setState(() {
        _activeFlashSale = flashSale;
        if (flashSale != null && flashSale.books.isNotEmpty) {
          _flashSaleBooks = flashSale.books;
          _flashEndsAt = flashSale.endAt;
          _timeLeft = flashSale.timeRemaining ?? Duration.zero;
          
          debugPrint('[HomePage] Setting flash sale books: ${_flashSaleBooks.length}');
          
          // Start auto-scroll timer
          _flashTimer?.cancel();
          if (_flashSaleBooks.length > 1) {
            _flashTimer = Timer.periodic(const Duration(seconds: 4), (_) {
              if (!_flashController.hasClients || _flashSaleBooks.length <= 1) return;
              final next = (_flashIndex + 1) % _flashSaleBooks.length;
              _flashController.animateToPage(
                next,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            });
          }
          
          // Start countdown timer
          _countdownTimer?.cancel();
          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            if (_activeFlashSale != null) {
              final remaining = _activeFlashSale!.timeRemaining;
              if (remaining != null && !remaining.isNegative) {
                setState(() {
                  _timeLeft = remaining;
                });
              } else {
                // Flash sale ended, reload to check for new one
                debugPrint('[HomePage] Flash sale ended, reloading...');
                _loadFlashSale();
              }
            }
          });
        } else {
          // No active flash sale or no books, clear flash sale data
          debugPrint('[HomePage] No flash sale or empty books, clearing data');
          _flashSaleBooks = [];
          _flashEndsAt = DateTime.now();
          _timeLeft = Duration.zero;
          _flashTimer?.cancel();
          _countdownTimer?.cancel();
        }
      });
    } catch (e) {
      debugPrint('[HomePage] Error loading flash sale: $e');
      if (!mounted) return;
      // Clear flash sale on error
      setState(() {
        _activeFlashSale = null;
        _flashSaleBooks = [];
        _flashEndsAt = DateTime.now();
        _timeLeft = Duration.zero;
        _flashTimer?.cancel();
        _countdownTimer?.cancel();
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (_) {
      // Ignore errors, keep count at 0
    }
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
    final featuredByRating = [..._currentBooks]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final featuredBooks = featuredByRating.take(5).toList();
    final bestSellerBooks = [..._currentBooks]
      ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
    final bestSellerTop5 = bestSellerBooks.take(5).toList();
    // Flash books are only from active flash sale

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
          notificationCount: _unreadNotificationCount,
          onNotificationTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationListPage(
                  baseUrl: widget.baseUrl,
                  token: widget.token,
                  userId: widget.userId,
                ),
              ),
            );
            // Reload count when returning from notification page
            _loadUnreadNotificationCount();
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 16),
              // Show flash sale section if there's a flash sale with books
              // Backend already filters for active flash sales, so we can trust it
              if (_activeFlashSale != null && _flashSaleBooks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _FlashHeader(timeLeft: _timeLeft),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _flashController,
                    itemCount: _flashSaleBooks.length,
                    onPageChanged: (index) {
                      setState(() {
                        _flashIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final book = _flashSaleBooks[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _FlashCard(
                          book: book,
                          flashSale: _activeFlashSale,
                          onTap: () => widget.onOpenBook(book),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_flashSaleBooks.length, (index) {
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
                const SizedBox(height: 24),
              ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.orange100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: AppColors.orange600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Danh mục',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                          letterSpacing: -0.3,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
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
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLASH SALE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kết thúc sau',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _TimeChip(value: hours),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              _TimeChip(value: minutes),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              _TimeChip(value: seconds),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFFFF3366),
        ),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({
    required this.book,
    this.flashSale,
    required this.onTap,
  });

  final Book book;
  final FlashSale? flashSale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use flash sale discount if available, otherwise use book discount
    final discountPercent = flashSale?.discountPercent ?? book.discount;
    final hasDiscount = discountPercent > 0;
    final discountPrice = hasDiscount
        ? book.price * (1 - discountPercent / 100)
        : book.price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(
            color: AppColors.gray100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with discount badge
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book.cover,
                      width: 100,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
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
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${discountPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flash sale tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 12,
                            color: Color(0xFFFF3366),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Flash Sale',
                            style: TextStyle(
                              color: Color(0xFFFF3366),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray500),
                    ),
                    const Spacer(),
                    // Price section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original price (strikethrough)
                        if (hasDiscount)
                          Text(
                            formatPrice(book.price),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.gray400,
                            ),
                          ),
                        const SizedBox(height: 2),
                        // Discount price
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Color(0xFFFF3366),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatPrice(discountPrice),
                              style: const TextStyle(
                                color: Color(0xFFFF3366),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
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
