// lib/core/widgets/location_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/vietnam_locations_service.dart';

/// Location Picker Widget - Allows user to select location from map + dropdown
class LocationPickerWidget extends StatefulWidget {
  final String title;
  final String selectedProvince;
  final Function(String province, String? district, LatLng coordinates) onLocationSelected;
  final List<String> availableProvinces;

  const LocationPickerWidget({
    super.key,
    required this.title,
    required this.selectedProvince,
    required this.onLocationSelected,
    this.availableProvinces = const [],
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late String selectedProvince;
  String? selectedDistrict;
  late LatLng selectedCoordinates;

  @override
  void initState() {
    super.initState();
    selectedProvince = widget.selectedProvince;
    selectedCoordinates = VietnamLocationsService.getProvinceCoordinates(selectedProvince);
    selectedDistrict = null;
  }

  @override
  Widget build(BuildContext context) {
    final provinces = widget.availableProvinces.isEmpty 
        ? VietnamLocationsService.getAllProvinces()
        : widget.availableProvinces;
    
    final districts = VietnamLocationsService.getDistrictsForProvince(selectedProvince);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Province Dropdown
        DropdownButtonFormField<String>(
          value: selectedProvince,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
          ),
          hint: const Text('Chọn tỉnh/thành phố'),
          items: provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedProvince = value;
                selectedDistrict = null; // Reset district
                selectedCoordinates = VietnamLocationsService.getProvinceCoordinates(value);
              });
              _notifySelection();
            }
          },
        ),
        const SizedBox(height: 12),

        // District/Ward Dropdown (if available)
        if (districts.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: selectedDistrict,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.location_on, color: Colors.orange),
            ),
            hint: const Text('Chọn phường/quận/huyện (tùy chọn)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Trung tâm tỉnh')),
              ...districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
            ],
            onChanged: (value) {
              setState(() {
                selectedDistrict = value;
                if (value != null) {
                  selectedCoordinates = VietnamLocationsService.getDistrictCoordinates(
                    selectedProvince,
                    value,
                  );
                } else {
                  selectedCoordinates = VietnamLocationsService.getProvinceCoordinates(selectedProvince);
                }
              });
              _notifySelection();
            },
          ),
          const SizedBox(height: 12),
        ],

        // Selected Location Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí đã chọn: $selectedProvince',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (selectedDistrict != null)
                          Text(
                            selectedDistrict!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        Text(
                          'GPS: ${selectedCoordinates.latitude.toStringAsFixed(4)}, ${selectedCoordinates.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Map Preview Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showMapPreview(),
            icon: const Icon(Icons.map),
            label: const Text('Xem trên bản đồ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _notifySelection() {
    widget.onLocationSelected(
      selectedProvince,
      selectedDistrict,
      selectedCoordinates,
    );
  }

  void _showMapPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bản đồ: $selectedProvince',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: selectedCoordinates,
                      initialZoom: 9.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.green_route_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedCoordinates,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const Text(
                                  'Vị trí',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
