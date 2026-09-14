import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/profile/presentation/profile_screen.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier()
      : super(const CityState(
          cities: [
            City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: 'RUH', latitude: 24.7136, longitude: 46.6753, isActive: 1),
            City(id: 2, nameEn: 'Jeddah', nameAr: 'جدة', regionCode: 'JED', latitude: 21.4858, longitude: 39.1925, isActive: 1),
          ],
          selectedCity: City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: 'RUH', latitude: 24.7136, longitude: 46.6753, isActive: 1),
        ));

  @override
  Future<void> fetchCities() async {}

  @override
  Future<void> selectCity(City? city) async {}

  @override
  Future<void> clearCityFilter() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProfileScreen renders Guest Welcome Card with Sign In / Register buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Guest header & quick action buttons
    expect(find.text('Welcome to DealSpot'), findsOneWidget);
    expect(find.text('User Sign In'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);

    // Verify Preferences items
    expect(find.text('PREFERENCES & PARTNER'), findsOneWidget);
    expect(find.text('Selected City'), findsOneWidget);
    expect(find.text('Language / اللغة'), findsOneWidget);
    expect(find.text('Partner With Us (Register Store)'), findsOneWidget);
    expect(find.text('Admin Portal Access'), findsOneWidget);
  });

  testWidgets('ProfileScreen opens City Selection BottomSheet on Selected City tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityNotifier()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Selected City
    await tester.tap(find.text('Selected City'));
    await tester.pumpAndSettle();

    // Bottom sheet should open with "Select Your City"
    expect(find.text('Select Your City'), findsOneWidget);
    expect(find.text('All Cities'), findsOneWidget);
    expect(find.text('Jeddah'), findsOneWidget);
  });
}
