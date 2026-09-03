import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import 'api_client.dart';

class CityState {
  final List<City> cities;
  final City? selectedCity;
  final bool isLoading;
  final String? errorMessage;

  const CityState({
    required this.cities,
    this.selectedCity,
    this.isLoading = false,
    this.errorMessage,
  });

  CityState copyWith({
    List<City>? cities,
    City? selectedCity,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedCity = false,
  }) {
    return CityState(
      cities: cities ?? this.cities,
      selectedCity: clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CityNotifier extends StateNotifier<CityState> {
  final ApiClient _apiClient;

  CityNotifier(this._apiClient) : super(const CityState(cities: [], isLoading: true)) {
    fetchCities();
    _loadSelectedCity();
  }

  static const String _cityCacheKey = 'dealspot_selected_city';

  Future<void> fetchCities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/cities/fetch-all');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(cities: list, isLoading: false);
        _syncSelectedCity(list);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cityCacheKey);
    if (cached != null) {
      try {
        final city = City.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        state = state.copyWith(selectedCity: city);
      } catch (e) {
        _setDefaultCity();
      }
    } else {
      _setDefaultCity();
    }
  }

  void _syncSelectedCity(List<City> cities) {
    if (state.selectedCity != null) {
      final matched = cities.where((c) => c.id == state.selectedCity!.id).firstOrNull;
      if (matched != null) {
        selectCity(matched);
        return;
      }
    }
    _setDefaultCity();
  }

  void _setDefaultCity() {
    if (state.cities.isEmpty) return;
    final riyadh = state.cities.where((c) => c.id == 1).firstOrNull ?? state.cities.first;
    selectCity(riyadh);
  }

  Future<void> selectCity(City city) async {
    state = state.copyWith(selectedCity: city);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityCacheKey, jsonEncode(city.toJson()));
  }

  // Admin CRUD
  Future<bool> createCity(String nameEn, String nameAr, String regionCode, double lat, double lng, int isActive) async {
    try {
      final response = await _apiClient.post(
        '/cities/create',
        data: {
          'nameEn': nameEn,
          'nameAr': nameAr,
          'regionCode': regionCode,
          'latitude': lat,
          'longitude': lng,
          'isActive': isActive == 1,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final created = City.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(cities: [...state.cities, created]);
        return true;
      }
    } catch (e) {
      debugPrint('Error creating city: $e');
    }

    // Local fallback for offline mode
    final newId = state.cities.isEmpty ? 1 : state.cities.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final newCity = City(
      id: newId,
      nameEn: nameEn,
      nameAr: nameAr,
      regionCode: regionCode,
      latitude: lat,
      longitude: lng,
      isActive: isActive,
    );
    state = state.copyWith(cities: [...state.cities, newCity]);
    return true;
  }

  Future<bool> updateCity(int id, String nameEn, String nameAr, String regionCode, double lat, double lng, int isActive) async {
    try {
      await _apiClient.put(
        '/cities/edit/$id',
        data: {
          'nameEn': nameEn,
          'nameAr': nameAr,
          'regionCode': regionCode,
          'latitude': lat,
          'longitude': lng,
          'isActive': isActive == 1,
        },
      );
    } catch (e) {
      debugPrint('Error updating city: $e');
    }

    final updatedList = state.cities.map((c) {
      if (c.id == id) {
        final updated = c.copyWith(
          nameEn: nameEn,
          nameAr: nameAr,
          regionCode: regionCode,
          latitude: lat,
          longitude: lng,
          isActive: isActive,
        );
        if (state.selectedCity?.id == id) {
          selectCity(updated);
        }
        return updated;
      }
      return c;
    }).toList();
    state = state.copyWith(cities: updatedList);
    return true;
  }

  Future<bool> deleteCity(int id) async {
    try {
      await _apiClient.delete('/cities/delete/$id');
    } catch (e) {
      debugPrint('Error deleting city: $e');
    }

    state = state.copyWith(
      cities: state.cities.where((c) => c.id != id).toList(),
    );
    if (state.selectedCity?.id == id) {
      _setDefaultCity();
    }
    return true;
  }
}

final cityRepositoryProvider = StateNotifierProvider<CityNotifier, CityState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CityNotifier(apiClient);
});
