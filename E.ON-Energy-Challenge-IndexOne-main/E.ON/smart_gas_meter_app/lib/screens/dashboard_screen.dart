import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_gas_meter_app/models/reading.dart';
import 'package:smart_gas_meter_app/screens/history_screen.dart';
import 'package:smart_gas_meter_app/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<Reading>> _readingsFuture;

  double _intervalValue = 60;
  bool _intervalLoading = true;
  bool _intervalSaving = false;

  Map<String, dynamic>? _analyticsData;
  bool _analyticsLoading = true;

  Map<String, dynamic>? _predictionData;
  bool _predictionLoading = true;

  @override
  void initState() {
    super.initState();
    _readingsFuture = _apiService.fetchReadings();
    _loadRequestInterval();
    _loadAnalytics();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    try {
      final data = await _apiService.fetchPrediction();

      if (!mounted) return;

      setState(() {
        _predictionData = data;
        _predictionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _predictionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load prediction: $e'),
        ),
      );
    }
  }

  Future<void> _loadRequestInterval() async {
    try {
      final interval = await _apiService.fetchRequestInterval();

      if (!mounted) return;

      setState(() {
        final clamped = interval.clamp(10, 255);
        _intervalValue = ((clamped / 5).round() * 5).toDouble();
        _intervalLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _intervalLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load interval: $e'),
        ),
      );
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await _apiService.fetchAnalytics();

      if (!mounted) return;

      setState(() {
        _analyticsData = data;
        _analyticsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analyticsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
        ),
      );
    }
  }

  Future<void> _saveRequestInterval() async {
    setState(() {
      _intervalSaving = true;
    });

    try {
      final intervalToSend = ((_intervalValue / 5).round() * 5).clamp(10, 255);

      await _apiService.updateRequestInterval(intervalToSend);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request interval updated to $intervalToSend seconds',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update interval: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _intervalSaving = false;
      });
    }
  }

  void _refreshReadings() {
    setState(() {
      _readingsFuture = _apiService.fetchReadings();
      _analyticsLoading = true;
      _predictionLoading = true;
    });
    _loadAnalytics();
    _loadPrediction();
  }

  String _formatReadingValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime dt) {
    final adjusted = dt.add(const Duration(hours: 2));

    final day = adjusted.day.toString().padLeft(2, '0');
    final month = adjusted.month.toString().padLeft(2, '0');
    final year = adjusted.year.toString();
    final hour = adjusted.hour.toString().padLeft(2, '0');
    final minute = adjusted.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  List<Reading> _getChartReadings(List<Reading> readings) {
    final filtered = readings
        .where((r) => (r.status ?? '').toUpperCase() == 'SUCCESS')
        .where((r) => r.value > 0)
        .toList();

    filtered.sort((a, b) => a.date.compareTo(b.date));

    if (filtered.length > 8) {
      return filtered.sublist(filtered.length - 8);
    }

    return filtered;
  }

  double? _getLatestConsumptionDelta(List<Reading> readings) {
    final valid = readings
        .where((r) => (r.status ?? '').toUpperCase() == 'SUCCESS')
        .where((r) => r.value > 0)
        .toList();

    valid.sort((a, b) => b.date.compareTo(a.date));

    if (valid.length < 2) return null;

    final latest = valid[0];
    final previous = valid[1];

    final diff = latest.value - previous.value;

    if (diff < 0) return null;

    return diff;
  }

  Widget _buildAnalyticsChart(List<Reading> readings) {
    final chartReadings = _getChartReadings(readings);

    if (chartReadings.isEmpty) {
      return const Center(
        child: Text('No valid analytics data yet'),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < chartReadings.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), chartReadings[i].value),
      );
    }

    double minY = chartReadings.first.value;
    double maxY = chartReadings.first.value;

    for (final reading in chartReadings) {
      if (reading.value < minY) minY = reading.value;
      if (reading.value > maxY) maxY = reading.value;
    }

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartReadings.length) {
                  return const SizedBox.shrink();
                }

                final date = chartReadings[index].date.add(
                  const Duration(hours: 2),
                );

                final hour = date.hour.toString().padLeft(2, '0');
                final minute = date.minute.toString().padLeft(2, '0');

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$hour:$minute',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: spots,
            color: const Color(0xFFD30000),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedAnalyticsCard(List<Reading> readings) {
    final latestDelta = _getLatestConsumptionDelta(readings);

    final bool hasAnalytics = _analyticsData != null;
    final bool isAnomaly =
        hasAnalytics && _analyticsData!['is_anomaly'] == true;
    final String analyticsMessage =
        hasAnalytics ? (_analyticsData!['message'] ?? '').toString() : '';

    final predictedNextConsumption =
        _predictionData?['predicted_next_consumption'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumption Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consumption since last reading',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latestDelta == null
                        ? 'Not enough data'
                        : '+${_formatReadingValue(latestDelta)} m³',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasAnalytics
                    ? (isAnomaly
                        ? Colors.red.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08))
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _analyticsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasAnalytics
                                  ? (isAnomaly
                                      ? Icons.warning_amber_rounded
                                      : Icons.verified_rounded)
                                  : Icons.info_outline,
                              color: hasAnalytics
                                  ? (isAnomaly ? Colors.red : Colors.green)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasAnalytics
                                    ? (isAnomaly
                                        ? 'Analysis: Alert'
                                        : 'Analysis: Normal')
                                    : 'Analysis unavailable',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hasAnalytics
                                      ? (isAnomaly ? Colors.red : Colors.green)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasAnalytics
                              ? analyticsMessage
                              : 'No analytics data.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _predictionLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prediction',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          predictedNextConsumption == null
                              ? 'Not enough data'
                              : '${predictedNextConsumption.toString()} m³',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Expected next consumption',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Recent successful readings trend',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _buildAnalyticsChart(readings),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IndexOne'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<Reading>>(
          future: _readingsFuture,
          builder: (context, snapshot) {
            final bool loading =
                snapshot.connectionState == ConnectionState.waiting;
            final bool hasError = snapshot.hasError;
            final List<Reading> readings = snapshot.data ?? [];
            final Reading? latestReading =
                readings.isNotEmpty ? readings.first : null;

            return ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Latest Reading',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          )
                        else if (hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Failed to load reading:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (latestReading == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No readings available'),
                          )
                        else ...[
                          Text(
                            '${_formatReadingValue(latestReading.value)} m³',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Last update: ${_formatDateTime(latestReading.date)}',
                            textAlign: TextAlign.center,
                          ),
                          if (latestReading.status != null &&
                              latestReading.status!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                                children: [
                                  const TextSpan(text: 'Status: '),
                                  TextSpan(
                                    text: latestReading.status ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (latestReading.status?.toUpperCase() ==
                                              'SUCCESS')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshReadings,
                          child: const Text('Refresh Reading'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Interval',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adjust how often the device requests a new reading.',
                        ),
                        const SizedBox(height: 20),
                        if (_intervalLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('10s'),
                              Text('255s'),
                            ],
                          ),
                          Slider(
                            value: _intervalValue,
                            min: 10,
                            max: 255,
                            divisions: (255 - 10) ~/ 5,
                            label: '${_intervalValue.round()}s',
                            onChanged: (value) {
                              setState(() {
                                _intervalValue =
                                    ((value / 5).round() * 5).toDouble();
                              });
                            },
                          ),
                          Center(
                            child: Text(
                              'Selected: ${_intervalValue.round()} seconds',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _intervalSaving ? null : _saveRequestInterval,
                            child: _intervalSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Update Interval'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCombinedAnalyticsCard(readings),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('Read History'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}