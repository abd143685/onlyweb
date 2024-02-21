class Shop {
  String? name;
  double? latitude;
  double? longitude;

  Shop({required this.name, required this.latitude, required this.longitude});

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      name: json['shop_name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
