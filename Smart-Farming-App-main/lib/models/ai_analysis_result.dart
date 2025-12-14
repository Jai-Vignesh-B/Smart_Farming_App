class AIAnalysisResult {
  final String summary;
  final String recommendation;
  final String trend; // 'up', 'down', 'stable'

  AIAnalysisResult({
    required this.summary,
    required this.recommendation,
    required this.trend,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      summary: json['summary'] ?? '',
      recommendation: json['recommendation'] ?? '',
      trend: json['trend'] ?? 'stable',
    );
  }
}
