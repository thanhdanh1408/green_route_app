// lib/features/driver/screens/driver_route_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class DriverRouteSelectionScreen extends StatefulWidget {
  const DriverRouteSelectionScreen({super.key});

  @override
  State<DriverRouteSelectionScreen> createState() => _DriverRouteSelectionScreenState();
}

class _DriverRouteSelectionScreenState extends State<DriverRouteSelectionScreen> {
  String? fromProvince;
  String? toProvince;
  String? weight = '5';
  String? timeRange;

  final provinces = ['Gia Lai', 'Đắk Lắk', 'Kon Tum', 'Bình Định', 'Quảng Ngãi', 'Đà Nẵng'];
  final weights = ['5', '8', '10', '15', '20', '30'];

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        timeRange = '${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}';
      });
    }
  }

  bool get _canContinue => fromProvince != null && toProvince != null && timeRange != null;

  Future<void> _saveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone');
    
    // Save route to global keys
    await prefs.setBool('driver_has_route', true);
    await prefs.setString('driver_route_from', fromProvince!);
    await prefs.setString('driver_route_to', toProvince!);
    await prefs.setString('driver_route_weight', weight!);
    await prefs.setString('driver_route_time_range', timeRange!);
    
    // 🔒 Also save to user-specific keys for persistence across logouts
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString('driver_route_from_$userId', fromProvince!);
      await prefs.setString('driver_route_to_$userId', toProvince!);
      await prefs.setString('driver_route_weight_$userId', weight!);
      await prefs.setString('driver_route_time_range_$userId', timeRange!);
      await prefs.setBool('driver_has_route_$userId', true);
      debugPrint('✅ Saved route to user-specific keys for persistence');
    }
    
    debugPrint('✅ Route saved: $fromProvince → $toProvince, Weight: $weight, Time: $timeRange');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn tuyến'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Chào mừng!', style: AppTextStyle.headline2),
            const SizedBox(height: 10),
            const Text('Chọn tuyến để xem đơn hàng phù hợp', textAlign: TextAlign.center, style: AppTextStyle.body),
            const SizedBox(height: 40),
            _buildDropdown('Từ tỉnh *', fromProvince, (v) => setState(() => fromProvince = v), provinces),
            const SizedBox(height: 16),
            _buildDropdown('Đến tỉnh *', toProvince, (v) => setState(() => toProvince = v), provinces),
            const SizedBox(height: 16),
            _buildDropdown('Trọng tải *', weight, (v) => setState(() => weight = v), weights),
            const SizedBox(height: 16),
            // Date Picker
            InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(timeRange ?? 'Chọn thời gian', style: TextStyle(color: timeRange != null ? Colors.black87 : Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              label: 'Tiếp tục',
              onPressed: _canContinue
                  ? () async {
                      await _saveRoute();
                      Navigator.pushNamedAndRemoveUntil(context, '/driver_home', (route) => false);
                    }
                  : null,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.body),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          hint: const Text('Chọn'),
        ),
      ],
    );
  }
}