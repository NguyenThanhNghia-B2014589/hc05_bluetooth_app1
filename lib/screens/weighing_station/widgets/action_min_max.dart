import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final double selectedPercentage;
  final double minWeight;
  final double maxWeight;
  final Function(double) onPercentageChanged;

  const ActionBar({
    super.key, 
    required this.selectedPercentage,
    required this.minWeight,
    required this.maxWeight,
    required this.onPercentageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: selectedPercentage,
              items: const [
                DropdownMenuItem(value: 1.0, child: Text('1.0%')),
                DropdownMenuItem(value: 2.0, child: Text('2.0%')),
                DropdownMenuItem(value: 5.0, child: Text('5.0%')),
                DropdownMenuItem(value: 90.0, child: Text('test%')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPercentageChanged(value); // Gọi callback báo cho controller
                }
              } 
            ),
          ),
        ),
        
        // MIN/MAX
        Text(
          'MIN: ${minWeight.toStringAsFixed(3)} MAX: ${maxWeight.toStringAsFixed(3)} KG',
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54, fontSize: 20),
        ),
      ],
    );
  }
}