/// Board model representing a board entity
/// 
/// This model is used throughout the application to represent
/// board data from the API and in the UI.
class Board {
  final String id;
  final String name;

  Board({
    required this.id,
    required this.name,
  });

  /// Creates a Board from JSON data
  /// Handles both String and int types for id
  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'].toString(), // Converts int or String to String
      name: json['name'] as String,
    );
  }

  /// Converts Board to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'Board(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Board && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
