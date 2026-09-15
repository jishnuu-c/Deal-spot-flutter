import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/auth/presentation/auth_screen.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/api_client.dart';
import 'package:dealspot_flutter/core/services/storage_service.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockCityRepository extends CityNotifier {
  MockCityRepository() : super(ApiClient(StorageService())) {
    state = const CityState(
      cities: [
        City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: 'RUH', latitude: 24.7, longitude: 46.7, isActive: 1),
        City(id: 2, nameEn: 'Jeddah', nameAr: 'جدة', regionCode: 'JED', latitude: 21.5, longitude: 39.1, isActive: 1),
        City(id: 3, nameEn: 'Dammam', nameAr: 'الدمام', regionCode: 'DMM', latitude: 26.4, longitude: 50.1, isActive: 1),
      ],
      selectedCity: null,
      isLoading: false,
    );
  }
}

void main() {
  testWidgets('AuthScreen renders Login mode correctly with tabs and brand badge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              initialMode: AuthScreenMode.login,
              returnUrl: '/',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brand badge
    expect(find.text('DealSpot'), findsOneWidget);

    // Verify Welcome Back headline
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Verify 3 mode tabs
    expect(find.text('User Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets);
    expect(find.text('Admin Portal'), findsOneWidget);

    // Verify Login inputs
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('AuthScreen renders Register mode with Full Name, Phone, and City selection', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              initialMode: AuthScreenMode.register,
              returnUrl: '/',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Register headline
    expect(find.text('Create Your Account'), findsOneWidget);

    // Verify Register fields
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Mobile Phone'), findsOneWidget);
    expect(find.text('Primary City'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Complete Registration'), findsOneWidget);
  });

  testWidgets('AuthScreen renders Admin Portal mode with notice box and admin button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              initialMode: AuthScreenMode.admin,
              returnUrl: '/admin',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Admin Portal headline and notice box
    expect(find.text('Admin Portal'), findsWidgets);
    expect(find.text('Restricted Administration Area'), findsOneWidget);
    expect(find.text('Admin / Staff Email'), findsOneWidget);
    expect(find.text('Admin Password'), findsOneWidget);
    expect(find.text('Authorize & Open Admin Panel'), findsOneWidget);
    expect(find.text('Return to User Sign In'), findsOneWidget);
  });

  testWidgets('AuthScreen allows switching between tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              initialMode: AuthScreenMode.login,
              returnUrl: '/',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Tap top tab for Sign Up (first instance)
    await tester.tap(find.text('Sign Up').first);
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);

    // Tap top tab for Admin Portal
    await tester.tap(find.text('Admin Portal'));
    await tester.pumpAndSettle();
    expect(find.text('Restricted Administration Area'), findsOneWidget);
  });
}
