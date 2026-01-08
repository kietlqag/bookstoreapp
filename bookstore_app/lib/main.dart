import 'package:flutter/material.dart';

import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'models/auth_service.dart';
import 'models/auth_session.dart';
import 'models/book.dart';
import 'models/book_service.dart';
import 'models/cart_item.dart';
import 'models/cart_service.dart';
import 'models/category_service.dart';
import 'models/favorite_service.dart';
import 'models/review_service.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/welcome_page.dart';
import 'screens/book_detail_page.dart';
import 'screens/home_page.dart';
import 'widgets/app_colors.dart';

void main() {
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatefulWidget {
  const BookStoreApp({super.key});

  @override
  State<BookStoreApp> createState() => _BookStoreAppState();
}

class _BookStoreAppState extends State<BookStoreApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AuthSession? _session;
  late final AuthService _authService = AuthService(baseUrl: _resolveBaseUrl());
  late final CategoryService _categoryService =
      CategoryService(baseUrl: _resolveBaseUrl());
  late final BookService _bookService = BookService(baseUrl: _resolveBaseUrl());
  late final ReviewService _reviewService =
      ReviewService(baseUrl: _resolveBaseUrl());
  late final CartService _cartService =
      CartService(baseUrl: _resolveBaseUrl());
  late final FavoriteService _favoriteService =
      FavoriteService(baseUrl: _resolveBaseUrl());
  bool _hasSeenWelcome = false;
  bool _prefsLoaded = false;

  static const List<Book> _sampleBooks = [
    Book(
      id: 1,
      title: 'The Subtle Art of Not Giving Up',
      author: 'Mark Manson',
      price: 95000,
      rating: 4.8,
      cover:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description:
          'A practical guide to choosing what matters and letting go of the rest.',
      soldQuantity: 72,
      stockQuantity: 120,
    ),
    Book(
      id: 2,
      title: 'How to Win Friends',
      author: 'Dale Carnegie',
      price: 85000,
      rating: 4.9,
      cover:
          'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description:
          'Classic lessons on communication, empathy, and leadership.',
      soldQuantity: 95,
      stockQuantity: 140,
    ),
    Book(
      id: 3,
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      price: 79000,
      rating: 4.7,
      cover:
          'https://images.unsplash.com/photo-1524578271613-d550eacf6090?auto=format&fit=crop&w=800&q=80',
      category: 'Literature',
      description: 'A timeless story about destiny and following your dreams.',
      soldQuantity: 60,
      stockQuantity: 110,
    ),
    Book(
      id: 4,
      title: 'Cafe on the Edge',
      soldQuantity: 35,
      stockQuantity: 90,
      author: 'Tony Buoi Sang',
      price: 65000,
      rating: 4.6,
      cover:
          'https://images.unsplash.com/photo-1526243741027-444d633d7365?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description: 'Short stories and insights for a brighter daily routine.',
    ),
    Book(
      id: 5,
      title: 'Sapiens',
      soldQuantity: 120,
      stockQuantity: 160,
      author: 'Yuval Noah Harari',
      price: 189000,
      rating: 4.9,
      cover:
          'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=800&q=80',
      category: 'Science',
      description: 'A brief history of humankind from ancient to modern times.',
    ),
    Book(
      id: 6,
      title: 'Tuoi Tre Dang Gia Bao Nhieu',
      soldQuantity: 50,
      stockQuantity: 100,
      author: 'Rosie Nguyen',
      price: 79000,
      rating: 4.5,
      cover:
          'https://images.unsplash.com/photo-1528207776546-365bb710ee93?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description: 'Essays on youth, growth, and meaningful choices.',
    ),
    Book(
      id: 7,
      title: 'Atomic Habits',
      soldQuantity: 140,
      stockQuantity: 180,
      author: 'James Clear',
      price: 125000,
      rating: 4.8,
      cover:
          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description: 'Tiny changes, remarkable results for building habits.',
    ),
    Book(
      id: 8,
      title: 'Think and Grow Rich',
      soldQuantity: 80,
      stockQuantity: 130,
      author: 'Napoleon Hill',
      price: 99000,
      rating: 4.7,
      cover:
          'https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=800&q=80',
      category: 'Business',
      description: 'Principles for success and a mindset of abundance.',
    ),
    Book(
      id: 9,
      title: 'Family Without Blood',
      soldQuantity: 40,
      stockQuantity: 90,
      author: 'Hector Malot',
      price: 55000,
      rating: 4.6,
      cover:
          'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=800&q=80',
      category: 'Literature',
      description: 'A heartfelt journey of identity and belonging.',
    ),
    Book(
      id: 10,
      title: 'Rich Dad Poor Dad',
      soldQuantity: 65,
      stockQuantity: 120,
      author: 'Robert Kiyosaki',
      price: 109000,
      rating: 4.8,
      cover:
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?auto=format&fit=crop&w=800&q=80',
      category: 'Business',
      description: 'Personal finance lessons from two very different mentors.',
    ),
    Book(
      id: 11,
      title: 'Criminal Psychology',
      soldQuantity: 55,
      stockQuantity: 100,
      author: 'Diep Huong',
      price: 89000,
      rating: 4.5,
      cover:
          'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=800&q=80',
      category: 'Mind',
      description: 'Insights into the psychology behind criminal behavior.',
    ),
    Book(
      id: 12,
      title: 'Homo Deus',
      soldQuantity: 30,
      stockQuantity: 70,
      author: 'Yuval Noah Harari',
      price: 199000,
      rating: 4.9,
      cover:
          'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=800&q=80',
      category: 'Science',
      description: 'Speculations about the future of humanity.',
    ),
    Book(
      id: 13,
      title: 'Deep Work',
      soldQuantity: 90,
      stockQuantity: 150,
      author: 'Cal Newport',
      price: 119000,
      rating: 4.7,
      cover:
          'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=800&q=80',
      category: 'Skills',
      description: 'Rules for focused success in a distracted world.',
    ),
    Book(
      id: 14,
      title: 'Zero to One',
      soldQuantity: 45,
      stockQuantity: 95,
      author: 'Peter Thiel',
      price: 149000,
      rating: 4.6,
      cover:
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=800&q=80',
      category: 'Business',
      description: 'Build something new instead of copying what exists.',
    ),
    Book(
      id: 15,
      title: 'A Little Life',
      soldQuantity: 75,
      stockQuantity: 125,
      author: 'Hanya Yanagihara',
      price: 69000,
      rating: 4.9,
      cover:
          'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=800&q=80',
      category: 'Literature',
      description: 'A moving story about friendship and resilience.',
    ),
  ];
  List<Book> _books = List<Book>.from(_sampleBooks);
  int _booksReloadCounter = 0;

  List<CartItem> _cartItems = [];
  Set<int> _favoriteIds = <int>{};

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

  Future<void> _login(String email, String password) async {
    final session = await _authService.login(email: email, password: password);
    _applySession(session);
  }

  Future<void> _register(String fullName, String email, String password) async {
    await _authService.requestRegisterOtp(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  Future<void> _verifyOtp(String email, String code) async {
    final session = await _authService.verifyOtp(email: email, code: code);
    _applySession(session);
  }

  Future<void> _resendOtp(String email) async {
    await _authService.resendOtp(email: email);
  }

  Future<void> _socialRegister(String provider) async {
    if (provider == 'google') {
      try {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final account = await googleSignIn.signIn();
        if (account == null) {
          throw Exception('Đăng ký Google bị hủy hoặc thất bại.');
        }
      final displayName = account.displayName?.trim();
      final session = await _authService.socialRegister(
        provider: 'google',
        providerUserId: account.id,
        fullName: displayName != null && displayName.isNotEmpty
            ? displayName
            : 'Google user',
      );
      _applySession(session);
      return;
      } catch (error) {
        debugPrint('Google register error: $error');
        rethrow;
      }
    }

    if (provider == 'facebook') {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed.');
      }
      final data = await FacebookAuth.instance.getUserData(
        fields: 'email,name',
      );
      final providerUserId = data['id']?.toString() ?? '';
      final fullName = data['name']?.toString() ?? 'Facebook user';
      if (providerUserId.isEmpty) {
        throw Exception('Facebook account not found.');
      }
      final session = await _authService.socialRegister(
        provider: 'facebook',
        providerUserId: providerUserId,
        fullName: fullName,
      );
      _applySession(session);
    }
  }

  Future<void> _socialLogin(String provider) async {
    if (provider == 'google') {
      try {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final account = await googleSignIn.signIn();
        if (account == null) {
          throw Exception('Đăng nhập Google bị hủy hoặc thất bại.');
        }
        final session = await _authService.socialLogin(
          provider: 'google',
          providerUserId: account.id,
          email: account.email,
        );
        _applySession(session);
        return;
      } catch (error) {
        debugPrint('Google login error: $error');
        rethrow;
      }
    }

    if (provider == 'facebook') {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed.');
      }
      final data = await FacebookAuth.instance.getUserData(
        fields: 'email,name',
      );
      final providerUserId = data['id']?.toString() ?? '';
      final email = data['email']?.toString() ?? '';
      if (providerUserId.isEmpty) {
        throw Exception('Facebook account not found.');
      }
      final session = await _authService.socialLogin(
        provider: 'facebook',
        providerUserId: providerUserId,
        email: email,
      );
      _applySession(session);
    }
  }

  void _applySession(AuthSession session) {
    setState(() {
      _session = session;
    });
    _loadCartForUser(session.userId);
    _loadFavoritesForUser(session.userId);
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          books: _books,
          cartItems: _cartItems,
          favoriteIds: _favoriteIds,
          categoryService: _categoryService,
          onOpenBook: _openBookDetail,
          onIncreaseCart: _increaseCart,
          onDecreaseCart: _decreaseCart,
          onRemoveCart: _removeCart,
          onOrderCompleted: _removeCartItemsLocal,
          onToggleFavorite: _toggleFavorite,
          onLogout: _logout,
          userId: session.userId,
          token: session.token,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _loadWelcomeFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_welcome') ?? false;
    if (!seen) {
      await prefs.setBool('has_seen_welcome', true);
    }
    if (!mounted) return;
    setState(() {
      _hasSeenWelcome = seen;
      _prefsLoaded = true;
    });
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _bookService.fetchBooks();
      if (!mounted || books.isEmpty) return;
      // Always create a new list to ensure reference changes for proper UI updates
      setState(() {
        _books = List<Book>.from(books);
        _booksReloadCounter++; // Increment counter to force widget rebuild
      });
    } catch (_) {
      // Keep sample data when the backend is unavailable.
    }
  }

  Future<void> _loadCartForUser(int userId) async {
    if (userId <= 0) return;
    try {
      final items = await _cartService.fetchCart(userId);
      if (!mounted) return;
      setState(() {
        _cartItems = items;
      });
    } catch (_) {
      // Keep local cart when the backend is unavailable.
    }
  }

  Future<void> _loadFavoritesForUser(int userId) async {
    if (userId <= 0) return;
    try {
      final ids = await _favoriteService.fetchFavoriteIds(userId);
      if (!mounted) return;
      setState(() {
        _favoriteIds = ids;
      });
    } catch (_) {
      // Keep local favorites when the backend is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWelcomeFlag();
    _loadBooks();
  }

  void _logout() {
    setState(() {
      _session = null;
      _cartItems = [];
      _favoriteIds = <int>{};
    });
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: _login,
          onRegister: _openRegister,
          onForgot: _openForgot,
          onGoogleLogin: () => _socialLogin('google'),
          onFacebookLogin: () => _socialLogin('facebook'),
        ),
      ),
      (route) => false,
    );
  }

  void _addToCart(Book book) {
    _addToCartWithQuantity(book, 1);
  }

  void _addToCartWithQuantity(Book book, int quantity) async {
    final session = _session;
    if (session == null || session.userId <= 0) return;

    try {
      final item = await _cartService.addToCart(
        userId: session.userId,
        bookId: book.id,
        quantity: quantity,
      );
      if (!mounted) return;
      setState(() {
        final index =
            _cartItems.indexWhere((current) => current.id == item.id);
        if (index == -1) {
          _cartItems = [..._cartItems, item];
        } else {
          _cartItems[index] = item;
        }
      });
    } catch (_) {
      // Ignore sync failures to keep UI responsive.
    }
  }

  void _increaseCart(CartItem item) async {
    try {
      final updated = await _cartService.updateQuantity(
        cartId: item.id,
        quantity: item.quantity + 1,
      );
      if (!mounted || updated == null) return;
      setState(() {
        final index = _cartItems.indexWhere((current) => current.id == item.id);
        if (index == -1) return;
        _cartItems[index] = updated;
      });
    } catch (_) {
      // Ignore sync failures to keep UI responsive.
    }
  }

  void _decreaseCart(CartItem item) async {
    final newQty = item.quantity - 1;
    try {
      if (newQty <= 0) {
        await _cartService.removeItem(item.id);
        if (!mounted) return;
        setState(() {
          _cartItems.removeWhere((current) => current.id == item.id);
        });
        return;
      }

      final updated = await _cartService.updateQuantity(
        cartId: item.id,
        quantity: newQty,
      );
      if (!mounted || updated == null) return;
      setState(() {
        final index = _cartItems.indexWhere((current) => current.id == item.id);
        if (index == -1) return;
        _cartItems[index] = updated;
      });
    } catch (_) {
      // Ignore sync failures to keep UI responsive.
    }
  }

  void _removeCart(CartItem item) async {
    try {
      await _cartService.removeItem(item.id);
    } catch (_) {
      // Ignore sync failures to keep UI responsive.
    }
    if (!mounted) return;
    setState(() {
      _cartItems.removeWhere((current) => current.id == item.id);
    });
  }

  void _removeCartItemsLocal(List<int> cartItemIds) {
    if (cartItemIds.isEmpty) return;
    final ids = cartItemIds.toSet();
    setState(() {
      _cartItems.removeWhere((current) => ids.contains(current.id));
    });
  }

  Future<bool> _toggleFavorite(Book book) async {
    final session = _session;
    if (session == null || session.userId <= 0) {
      throw Exception('Vui lòng đăng nhập để yêu thích sách.');
    }

    final isFavorite = _favoriteIds.contains(book.id);
    if (isFavorite) {
      await _favoriteService.removeFavorite(
        userId: session.userId,
        bookId: book.id,
      );
    } else {
      await _favoriteService.addFavorite(
        userId: session.userId,
        bookId: book.id,
      );
    }

    if (!mounted) return !isFavorite;
    setState(() {
      final updated = Set<int>.from(_favoriteIds);
      if (isFavorite) {
        updated.remove(book.id);
      } else {
        updated.add(book.id);
      }
      _favoriteIds = updated;
    });
    return !isFavorite;
  }

  void _openBookDetail(Book book) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BookDetailPage(
          book: book,
          bookService: _bookService,
          reviewService: _reviewService,
          isFavorite: _favoriteIds.contains(book.id),
          onToggleFavorite: _toggleFavorite,
          onAddToCart: _addToCartWithQuantity,
          userId: _session?.userId ?? 0,
        ),
      ),
    );
  }

  void _openLogin() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: _login,
          onRegister: _openRegister,
          onForgot: _openForgot,
          onGoogleLogin: () => _socialLogin('google'),
          onFacebookLogin: () => _socialLogin('facebook'),
        ),
      ),
    );
  }

  void _openRegister() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RegisterPage(
          onRequestOtp: _register,
          onVerifyOtp: _verifyOtp,
          onResendOtp: _resendOtp,
          onLogin: _openLogin,
          onGoogleRegister: () => _socialRegister('google'),
          onFacebookRegister: () => _socialRegister('facebook'),
        ),
      ),
    );
  }

  void _openForgot() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          baseUrl: _resolveBaseUrl(),
          onBack: () {
            _navigatorKey.currentState?.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange600,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.gray50,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.gray100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: !_prefsLoaded
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _session != null
          ? HomePage(
              books: _books,
              cartItems: _cartItems,
              favoriteIds: _favoriteIds,
              categoryService: _categoryService,
              onOpenBook: _openBookDetail,
              onIncreaseCart: _increaseCart,
              onDecreaseCart: _decreaseCart,
              onRemoveCart: _removeCart,
              onOrderCompleted: (cartItemIds) {
                _removeCartItemsLocal(cartItemIds);
                // Reload books to update soldQuantity after order
                _loadBooks();
              },
              onReloadBooks: _loadBooks,
              onToggleFavorite: _toggleFavorite,
              onLogout: _logout,
              userId: _session?.userId ?? 0,
              token: _session?.token ?? '',
            )
          : (_hasSeenWelcome
              ? LoginPage(
                  onLogin: _login,
                  onRegister: _openRegister,
                  onForgot: _openForgot,
                  onGoogleLogin: () => _socialLogin('google'),
                  onFacebookLogin: () => _socialLogin('facebook'),
                )
              : WelcomePage(
                  onGetStarted: _openRegister,
                  onLogin: _openLogin,
                )),
    );
  }
}











