import 'package:flutter/material.dart';
import '../models/reading.dart';

class ReadingCard extends StatelessWidget {

  final Reading reading;

  const ReadingCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {

    return Card(
      child: ListTile(

        leading: const Icon(Icons.speed),

        title: Text("${reading.value} m³"),

        subtitle: Text(reading.date),

        trailing: Text(reading.status),

      ),
    );
  }
}