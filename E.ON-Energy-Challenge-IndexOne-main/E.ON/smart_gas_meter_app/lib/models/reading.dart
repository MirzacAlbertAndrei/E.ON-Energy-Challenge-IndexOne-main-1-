class Reading {
  final int id;
  final double value;
  final String date;
  final String status;

  Reading({
    required this.id,
    required this.value,
    required this.date,
    required this.status,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'],
      value: json['value'].toDouble(),
      date: json['date'],
      status: json['status'],
    );
  }
}