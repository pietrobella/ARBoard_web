class Net {
  final int id;
  final String name;

  Net({required this.id, required this.name});

  factory Net.fromJson(Map<String, dynamic> json) {
    return Net(id: json['id'], name: json['name'].toString());
  }
}
