class Component {
  final int id;
  final String name;

  Component({required this.id, required this.name});

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(id: json['id'], name: json['name'].toString());
  }
}

class Pin {
  final int id;
  final String name;

  Pin({required this.id, required this.name});

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(id: json['id'], name: json['name'].toString());
  }
}
