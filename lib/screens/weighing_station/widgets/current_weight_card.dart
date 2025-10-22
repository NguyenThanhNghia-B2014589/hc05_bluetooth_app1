import 'package:flutter/material.dart';
import '../../../services/bluetooth_service.dart';

class CurrentWeightCard extends StatelessWidget {
  final BluetoothService bluetoothService;
  const CurrentWeightCard({super.key, required this.bluetoothService});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trọng lượng hiện tại', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: bluetoothService.currentWeight,
                  builder: (context, weight, child) {
                    return Text(
                      weight.toStringAsFixed(3),
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text('Kg', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
              const SizedBox(height: 32),
              const Text('Chênh lệch: 0%'),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: 1.0, color: Colors.red),
          ],
        ),
      ),
    );
  }
}