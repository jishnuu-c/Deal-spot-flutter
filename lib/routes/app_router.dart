import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_repository.dart';

// Screens imports
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/partner_apply_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/offers/presentation/offer_list_screen.dart';
import '../features/offers/presentation/offer_detail_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/stores/presentation/store_list_screen.dart';
import '../features/stores/presentation/store_detail_screen.dart';
import '../features/stores/presentation/store_branches_screen.dart';
import '../features/flyers/presentation/flyer_list_screen.dart';
import '../features/flyers/presentation/flyer_viewer_screen.dart';
import '../features/profile/presentation/saved_offers_screen.dart';
import '../features/profile/presentation/followed_stores_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

// Admin screens
import '../features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import '../features/admin/presentation/cruds/partner_requests_crud_screen.dart';
import '../features/admin/presentation/cruds/cities_crud_screen.dart';
import '../features/admin/presentation/cruds/categories_crud_screen.dart';
import '../features/admin/presentation/cruds/stores_crud_screen.dart';
import '../features/admin/presentation/cruds/branches_crud_screen.dart';
import '../features/admin/presentation/cruds/products_crud_screen.dart';
import '../features/admin/presentation/cruds/brands_crud_screen.dart';
import '../features/admin/presentation/cruds/admin_product_detail_screen.dart';
import '../features/admin/presentation/cruds/product_specs_crud_screen.dart';
import '../features/admin/presentation/cruds/product_images_crud_screen.dart';
import '../features/admin/presentation/cruds/offers_crud_screen.dart';
import '../features/admin/presentation/cruds/offer_images_crud_screen.dart';
import '../features/admin/presentation/cruds/flyers_crud_screen.dart';
import '../features/admin/presentation/cruds/flyer_pages_crud_screen.dart';
import '../features/admin/presentation/cruds/coupons_crud_screen.dart';
import '../features/admin/presentation/cruds/users_crud_screen.dart';
import '../features/admin/presentation/cruds/notifications_crud_screen.dart';
import '../features/admin/presentation/cruds/audit_logs_screen.dart';

// Layout imports
import '../features/home/presentation/public_layout.dart';
import '../features/admin/presentation/dashboard/admin_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isAdminLoggedIn = authState.isAdminLoggedIn;
      final isGoingToLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // 1. Route protection: Admin pages
      if (state.matchedLocation.startsWith('/admin')) {
        if (!isAdminLoggedIn) {
          return '/login?admin=true&returnUrl=${Uri.encodeComponent(state.matchedLocation)}';
        }
        return null;
      }

      // 2. Protected customer pages
      final protectedCustomerPaths = [
        '/saved-offers',
        '/followed-stores',
        '/notifications',
        '/profile',
      ];

      final isProtectedCustomerPath = protectedCustomerPaths.any((path) => state.matchedLocation.startsWith(path));

      if (isProtectedCustomerPath && !isLoggedIn) {
        return '/login?returnUrl=${Uri.encodeComponent(state.matchedLocation)}';
      }

      // 3. Prevent logged in user from going back to login screen
      if (isGoingToLogin && isLoggedIn) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth Screens
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final adminParam = state.uri.queryParameters['admin'] == 'true';
          final returnUrl = state.uri.queryParameters['returnUrl'] ?? '/';
          return AuthScreen(
            initialMode: adminParam ? AuthScreenMode.admin : AuthScreenMode.login,
            returnUrl: returnUrl,
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final returnUrl = state.uri.queryParameters['returnUrl'] ?? '/';
          return AuthScreen(
            initialMode: AuthScreenMode.register,
            returnUrl: returnUrl,
          );
        },
      ),
      GoRoute(
        path: '/partner-with-us',
        builder: (context, state) => const PartnerApplyScreen(),
      ),

      // Public / Customer Shell Route inside PublicLayout
      ShellRoute(
        builder: (context, state, child) {
          return PublicLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/offers',
            builder: (context, state) {
              final catId = state.uri.queryParameters['categoryId'] ?? state.uri.queryParameters['category'];
              return OfferListScreen(
                categoryIdFilter: catId != null ? int.tryParse(catId) : null,
              );
            },
          ),
          GoRoute(
            path: '/offers-list',
            builder: (context, state) {
              final catId = state.uri.queryParameters['categoryId'] ?? state.uri.queryParameters['category'];
              return OfferListScreen(
                categoryIdFilter: catId != null ? int.tryParse(catId) : null,
              );
            },
          ),
          GoRoute(
            path: '/offers/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return OfferDetailScreen(offerId: id);
            },
          ),
          GoRoute(
            path: '/products/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ProductDetailScreen(productId: id);
            },
          ),
          GoRoute(
            path: '/stores',
            builder: (context, state) => const StoreListScreen(),
          ),
          GoRoute(
            path: '/stores/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StoreDetailScreen(storeId: id);
            },
          ),
          GoRoute(
            path: '/stores/:id/branches',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StoreBranchesScreen(storeId: id);
            },
          ),
          GoRoute(
            path: '/flyers',
            builder: (context, state) => const FlyerListScreen(),
          ),
          GoRoute(
            path: '/flyers/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return FlyerViewerScreen(flyerId: id);
            },
          ),
          GoRoute(
            path: '/categories/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return OfferListScreen(categoryIdFilter: id);
            },
          ),

          // Protected Customer Routes
          GoRoute(
            path: '/saved-offers',
            builder: (context, state) => const SavedOffersScreen(),
          ),
          GoRoute(
            path: '/followed-stores',
            builder: (context, state) => const FollowedStoresScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Admin Layout & Routes
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/partner-requests',
            builder: (context, state) => const PartnerRequestsCrudScreen(),
          ),
          GoRoute(
            path: '/admin/cities',
            builder: (context, state) => const CitiesCrudScreen(),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (context, state) => const CategoriesCrudScreen(),
          ),
          GoRoute(
            path: '/admin/stores',
            builder: (context, state) => const StoresCrudScreen(),
          ),
          GoRoute(
            path: '/admin/stores/:id/branches',
            builder: (context, state) {
              final storeId = int.parse(state.pathParameters['id']!);
              return BranchesCrudScreen(storeId: storeId);
            },
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const ProductsCrudScreen(),
          ),
          GoRoute(
            path: '/admin/brands',
            builder: (context, state) => const BrandsCrudScreen(),
          ),
          GoRoute(
            path: '/admin/products/:id/details',
            builder: (context, state) {
              final prodId = int.parse(state.pathParameters['id']!);
              return AdminProductDetailScreen(productId: prodId);
            },
          ),
          GoRoute(
            path: '/admin/product-specs/:id/details',
            builder: (context, state) {
              final prodId = int.parse(state.pathParameters['id']!);
              return ProductSpecsCrudScreen(productId: prodId);
            },
          ),
          GoRoute(
            path: '/admin/products/:id/images',
            builder: (context, state) {
              final prodId = int.parse(state.pathParameters['id']!);
              return ProductImagesCrudScreen(productId: prodId);
            },
          ),
          GoRoute(
            path: '/admin/offers',
            builder: (context, state) => const OffersCrudScreen(),
          ),
          GoRoute(
            path: '/admin/offers/:id/images',
            builder: (context, state) {
              final offerId = int.parse(state.pathParameters['id']!);
              return OfferImagesCrudScreen(offerId: offerId);
            },
          ),
          GoRoute(
            path: '/admin/flyers',
            builder: (context, state) => const FlyersCrudScreen(),
          ),
          GoRoute(
            path: '/admin/flyers/:id/pages',
            builder: (context, state) {
              final flyerId = int.parse(state.pathParameters['id']!);
              return FlyerPagesCrudScreen(flyerId: flyerId);
            },
          ),
          GoRoute(
            path: '/admin/coupons',
            builder: (context, state) => const CouponsCrudScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersCrudScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const NotificationsCrudScreen(),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
        ],
      ),
    ],
  );
});
