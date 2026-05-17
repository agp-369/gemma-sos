import 'package:flutter/material.dart';
import '../services/gps_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final GpsService _gps = GpsService();
  String _status = 'Initializing...';
  GeoPoint? _position;
  String _selectedCategory = 'shelter';
  String? _disclaimerShown;

  final List<Map<String, String>> _categories = [
    {'key': 'shelter', 'label': 'Shelters', 'icon': 'house'},
    {'key': 'hospital', 'label': 'Hospitals', 'icon': 'local_hospital'},
    {'key': 'water', 'label': 'Water', 'icon': 'water_drop'},
    {'key': 'food', 'label': 'Food', 'icon': 'restaurant'},
    {'key': 'fuel', 'label': 'Fuel', 'icon': 'local_gas_station'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final pos = await _gps.getCurrentPosition();
    setState(() {
      _position = pos;
      _status = pos.source == 'fallback'
          ? 'Using approximate location'
          : 'Location acquired';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text('KITSUNE MAP', style: TextStyle(letterSpacing: 2))),
      body: Column(
        children: [
          // Location banner
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _position != null
                        ? '${_position!.latitude.toStringAsFixed(4)}, '
                            '${_position!.longitude.toStringAsFixed(4)} '
                            '(${_position!.source})'
                        : _status,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Color(0xFFD4AF37)),
                  onPressed: _loadPosition,
                ),
              ],
            ),
          ),

          // Category chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat['key'];
                return ChoiceChip(
                  backgroundColor: const Color(0xFF1A1A1A),
                  selectedColor: const Color(0xFFD4AF37),
                  labelStyle: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFromString(cat['icon']!),
                        size: 16,
                        color: selected ? Colors.black : const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 4),
                      Text(cat['label']!),
                    ],
                  ),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      _selectedCategory = cat['key']!;
                      _disclaimerShown = null;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Search button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _position == null ? null : _showDisclaimer,
              icon: const Icon(Icons.search),
              label: Text('FIND NEARBY ${_selectedCategory.toUpperCase()}S'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
            ),
          ),

          // Disclaimer (shown once per category)
          if (_disclaimerShown != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B0000)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFD4AF37), size: 18),
                        SizedBox(width: 12),
                        Text(
                          'OFFLINE MAP DATA',
                          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_disclaimerShown!,
                        style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Offline mode indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('OFFLINE GEODATA ACTIVE',
                    style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimer() {
    setState(() {
      _disclaimerShown =
        'Offline map data is not bundled with this app to keep the APK size small. '
        'To use this feature, pre-download OpenStreetMap tiles for your area using '
        'a tool like OSMAnd or Organic Maps before going offline.\n\n'
        'Current position: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}\n'
        'Category: $_selectedCategory\n\n'
        'Tip: Mark known shelter/hospital locations on the triage dashboard as you discover them.';
    });
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'house':
        return Icons.house;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'water_drop':
        return Icons.water_drop;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.place;
    }
  }
}
