import 'package:flutter/material.dart';
import '../models/reading.dart';

class ReadingCard extends StatelessWidget {
  final Reading reading;

  const ReadingCard({super.key, required this.reading});

  String _formatDate(DateTime date) {
    final adjusted = date.add(const Duration(hours: 2));

    final day = adjusted.day.toString().padLeft(2, '0');
    final month = adjusted.month.toString().padLeft(2, '0');
    final year = adjusted.year.toString();
    final hour = adjusted.hour.toString().padLeft(2, '0');
    final minute = adjusted.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final status = reading.status ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.speed),
        title: Text('${reading.value} m³'),
        subtitle: Text(_formatDate(reading.date)),
        trailing: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: status.toUpperCase() == 'SUCCESS'
                ? Colors.green
                : Colors.red,
          ),
        ),
      ),
    );
  }
}