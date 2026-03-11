import 'package:flutter/material.dart';
import 'package:smart_gas_meter_app/models/reading.dart';
import 'package:smart_gas_meter_app/services/api_service.dart';
import 'package:smart_gas_meter_app/widgets/reading_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Reading>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _readingsFuture = _apiService.fetchReadings();
  }

  void _refreshHistory() {
    setState(() {
      _readingsFuture = _apiService.fetchReadings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
      ),
      body: FutureBuilder<List<Reading>>(
        future: _readingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load history:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshHistory,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final readings = snapshot.data ?? [];

          if (readings.isEmpty) {
            return const Center(
              child: Text('No readings available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshHistory();
              await _readingsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                return ReadingCard(reading: readings[index]);
              },
            ),
          );
        },
      ),
    );
  }
}