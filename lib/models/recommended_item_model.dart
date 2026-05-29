class RecommendedItem {
  final int id;
  final String appName;
  final String recommendedValue;

  RecommendedItem({
    required this.id,
    required this.appName,
    required this.recommendedValue,
  });

  factory RecommendedItem.fromMap(Map<String, dynamic> map) {
    return RecommendedItem(
      id: map['id'],
      appName: map['appName'] ?? '',
      recommendedValue: map['recommendedValue'] ?? '',
    );
  }
}
