import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/hourly_weighing_chart.dart';
import 'widgets/inventory_pie_chart.dart';
import '../../widgets/date_picker_input.dart';
import 'controllers/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BluetoothService _bluetoothService = BluetoothService();

  // --- 2. Create Controller ---
  late final DashboardController _controller;
  // Use a separate controller for the date picker text field
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // --- 3. Initialize Controller ---
    _controller = DashboardController();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_controller.selectedDate);

    // Add listener to update text field if controller date changes internally (optional but good practice)
    _controller.addListener(() {
        final formattedDate = DateFormat('dd/MM/yyyy').format(_controller.selectedDate);
        if (_dateController.text != formattedDate) {
           _dateController.text = formattedDate;
        }
    });
  }

  @override
  void dispose() {
    // --- 4. Dispose Controllers ---
    _controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ',
        bluetoothService: _bluetoothService,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại trang chủ',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- 5. Use AnimatedBuilder to listen ---
      body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              color: const Color(0xFFE3F2FD),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Khối Lượng Cân Theo Ca',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      DatePickerInput(
                        selectedDate: _controller.selectedDate, // <-- Get from controller
                        controller: _dateController, // Use the local controller for text field
                        onDateSelected: (newDate) {
                          _controller.updateSelectedDate(newDate); // <-- Call controller method
                        },
                        onDateCleared: () { // Reset to today
                          _controller.updateSelectedDate(DateTime.now()); // <-- Call controller method
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bar Chart Column
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // --- 6. Get data from controller ---
                            child: HourlyWeighingChart(data: _controller.chartData),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Pie Chart Column
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // --- 7. Get data from controller ---
                            child: InventoryPieChart(
                              totalNhap: _controller.totalNhap,
                              totalXuat: _controller.totalXuat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}