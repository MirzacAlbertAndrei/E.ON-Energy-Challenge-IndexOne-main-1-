import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reading.dart';
import '../widgets/reading_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  List<Reading> readings = [];

  int interval = 30;

  @override
  void initState() {
    super.initState();
    loadReadings();
  }

  Future<void> loadReadings() async {
    readings = await ApiService.getReadings();
    setState(() {});
  }

  void changeInterval() async {

    await ApiService.setInterval(interval);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Interval Updated")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Gas Meter Dashboard"),
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const Text(
                    "Request Interval",
                    style: TextStyle(fontSize: 18),
                  ),

                  Slider(
                    min: 10,
                    max: 120,
                    divisions: 11,
                    value: interval.toDouble(),
                    label: "$interval sec",
                    onChanged: (value) {
                      setState(() {
                        interval = value.toInt();
                      });
                    },
                  ),

                  ElevatedButton(
                    onPressed: changeInterval,
                    child: const Text("Update Interval"),
                  )

                ],
              ),
            ),
          ),

          const Text(
            "Reading History",
            style: TextStyle(fontSize: 20),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadReadings,
              child: ListView.builder(
                itemCount: readings.length,
                itemBuilder: (context, index) {
                  return ReadingCard(reading: readings[index]);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}