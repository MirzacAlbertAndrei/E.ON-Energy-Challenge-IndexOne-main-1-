class Reading {
  final int id;
  final double value;
  final DateTime date;
  final String? status;

  Reading({
    required this.id,
    required this.value,
    required this.date,
    this.status,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['date'] ?? '').toString().replaceFirst(' ', 'T');

    return Reading(
      id: json['id'] ?? 0,
      value: (json['value'] as num).toDouble(),
      date: DateTime.parse(rawDate),
      status: json['status']?.toString(),
    );
  }
}