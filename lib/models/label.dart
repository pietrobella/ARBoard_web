class Label {
  final int id;
  final String name;
  final String? description;
  final int? boardId;
  final List<SubLabel> sublabels;

  Label({
    required this.id,
    required this.name,
    this.description,
    this.boardId,
    this.sublabels = const [],
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      boardId: json['board_id'],
      sublabels:
          (json['sublabels'] as List<dynamic>?)
              ?.map((e) => SubLabel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubLabel {
  final int id;
  final String name;
  final int? labelId;

  SubLabel({required this.id, required this.name, this.labelId});

  factory SubLabel.fromJson(Map<String, dynamic> json) {
    return SubLabel(
      id: json['id'],
      name: json['name'],
      labelId: json['label_id'],
    );
  }
}
