import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double height;
  final bool isRtl;
  final bool isDark;
  final void Function(double lat, double lng) onLocationChanged;

  const LocationPickerWidget({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.height = 240,
    this.isRtl = false,
    this.isDark = false,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late double _currentLat;
  late double _currentLng;
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  bool _isSearching = false;
  double _zoom = 11.0;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat != 0.0 ? widget.initialLat : 24.7136;
    _currentLng = widget.initialLng != 0.0 ? widget.initialLng : 46.6753;
    _mapController = MapController();
    _latController.text = _currentLat.toStringAsFixed(4);
    _lngController.text = _currentLng.toStringAsFixed(4);
  }

  @override
  void didUpdateWidget(covariant LocationPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.initialLat != widget.initialLat || oldWidget.initialLng != widget.initialLng) &&
        (widget.initialLat != _currentLat || widget.initialLng != _currentLng)) {
      setState(() {
        _currentLat = widget.initialLat != 0.0 ? widget.initialLat : 24.7136;
        _currentLng = widget.initialLng != 0.0 ? widget.initialLng : 46.6753;
        _latController.text = _currentLat.toStringAsFixed(4);
        _lngController.text = _currentLng.toStringAsFixed(4);
      });
      _mapController.move(LatLng(_currentLat, _currentLng), _zoom);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _updateLocation(double lat, double lng, {bool moveMap = true}) {
    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _latController.text = lat.toStringAsFixed(4);
      _lngController.text = lng.toStringAsFixed(4);
    });
    if (moveMap) {
      _mapController.move(LatLng(lat, lng), _zoom);
    }
    widget.onLocationChanged(lat, lng);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final dio = Dio();
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1';
      final response = await dio.get(
        url,
        options: Options(headers: {'User-Agent': 'DealSpotFlutterApp/1.0'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data is List ? response.data as List : jsonDecode(response.data as String) as List;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat'].toString()) ?? _currentLat;
          final lon = double.tryParse(first['lon'].toString()) ?? _currentLng;
          _updateLocation(lat, lon);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isRtl ? 'لم يتم العثور على نتائج' : 'No locations found'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _locateMe() {
    // Center to Riyadh / Saudi Arabia default hub or user location
    _updateLocation(24.7136, 46.6753);
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3.0, 18.0);
      _mapController.move(LatLng(_currentLat, _currentLng), _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3.0, 18.0);
      _mapController.move(LatLng(_currentLat, _currentLng), _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isRtl = widget.isRtl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Toolbar Header: Search & GPS Button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchLocation(),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isRtl
                          ? 'ابحث عن مكان، مول، أو شارع...'
                          : 'Search place, mall, or street...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 17,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      suffixIcon: InkWell(
                        onTap: _isSearching ? null : _searchLocation,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 38),
                ),
                icon: const Icon(Icons.my_location, size: 15),
                label: Text(
                  isRtl ? 'موقعي' : 'My Location',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                onPressed: _locateMe,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Map Render Container (OpenStreetMap Tiles with Pins & Controls)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_currentLat, _currentLng),
                      initialZoom: _zoom,
                      onTap: (tapPosition, point) {
                        _updateLocation(point.latitude, point.longitude, moveMap: false);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.dealspot.dealspot_flutter',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentLat, _currentLng),
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF2563EB),
                              size: 40,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Zoom Controls (+ / -)
                  Positioned(
                    top: 10,
                    left: isRtl ? null : 10,
                    right: isRtl ? 10 : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _zoomIn,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add, size: 18, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          InkWell(
                            onTap: _zoomOut,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.remove, size: 18, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Map Hint Pill
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app, size: 13, color: Color(0xFF4ADE80)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isRtl
                                    ? 'انقر على الخريطة أو اسحب الدبوس لتحديد الموقع'
                                    : 'Click map or drag pin to select location',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Coordinates Display & Manual Adjustment Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRtl ? 'خط العرض' : 'Latitude',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 76,
                      height: 30,
                      child: TextField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        onSubmitted: (val) {
                          final lat = double.tryParse(val) ?? _currentLat;
                          _updateLocation(lat, _currentLng);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRtl ? 'خط الطول' : 'Longitude',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 76,
                      height: 30,
                      child: TextField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        onSubmitted: (val) {
                          final lng = double.tryParse(val) ?? _currentLng;
                          _updateLocation(_currentLat, lng);
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentLat.toStringAsFixed(2)}, ${_currentLng.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
