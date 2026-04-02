import 'package:flutter/material.dart';

class SingleChoice extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final Function(String) onChanged;

  const SingleChoice({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.black87 : Colors.black54,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(180),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.black87)
                : null,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}