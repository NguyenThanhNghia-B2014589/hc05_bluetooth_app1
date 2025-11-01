import 'package:flutter/material.dart';
import '../../../services/bluetooth_service.dart';

class CurrentWeightCard extends StatelessWidget {
  final BluetoothService bluetoothService;
  final double minWeight;
  final double maxWeight;
  final double khoiLuongMe;

  const CurrentWeightCard({
    super.key,
    required this.bluetoothService,
    required this.minWeight,
    required this.maxWeight,
    required this.khoiLuongMe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder<double>(
          valueListenable: bluetoothService.currentWeight,
          builder: (context, currentWeight, child) {
            final bool isInRange = (currentWeight >= minWeight) && (currentWeight <= maxWeight);
            final Color statusColor = isInRange ? Colors.green : Colors.red;
            final double deviationPercent = (khoiLuongMe == 0)
                ? 0
                : ((currentWeight - khoiLuongMe) / khoiLuongMe) * 100;
            final String deviationString =
                '${deviationPercent > 0 ? '+' : ''}${deviationPercent.toStringAsFixed(1)}%';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với MIN/MAX ở góc phải
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trọng lượng hiện tại',
                      style: TextStyle(fontSize: 16),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 8),
                
                // Trọng lượng hiện tại
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(3),
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('Kg', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MIN: ${minWeight.toStringAsFixed(2)} KG',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 30),
                        Text(
                          'MAX: ${maxWeight.toStringAsFixed(2)} KG',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 32),

                // Chênh lệch
                Text(
                  'Chênh lệch: $deviationString',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 1.0,
                  color: statusColor,
                  backgroundColor: statusColor.withValues(alpha: 0.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}