class PlaceNameModel {
  final int? id;
  final String placeName;

//constructor
  PlaceNameModel({
    this.id,
    required this.placeName,
  });

//fromJson
  factory PlaceNameModel.fromJson(Map<String, dynamic> json) {
    return PlaceNameModel(
      id: json['id'] as int?,
      placeName: json['placeName'],
    );
  }

//toJson

  Map<String, dynamic> toJson() {
    return {
      'placeName': placeName,
    };
  }
}
