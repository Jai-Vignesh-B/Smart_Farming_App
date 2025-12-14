class SoilData {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final DateTime? timestamp;

  SoilData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    this.timestamp,
  });

  factory SoilData.fromMap(Map<dynamic, dynamic> map) {
    return SoilData(
      nitrogen: double.tryParse(map['N']?.toString() ?? '0') ?? 0,
      phosphorus: double.tryParse(map['P']?.toString() ?? '0') ?? 0,
      potassium: double.tryParse(map['K']?.toString() ?? '0') ?? 0,
      timestamp: DateTime.now(), // Realtime DB doesn't always have a timestamp, using now() as fallback
    );
  }

  @override
  String toString() => 'N: $nitrogen, P: $phosphorus, K: $potassium';
}
