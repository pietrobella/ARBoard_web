class CropSchematic {
  final int id;
  final int boardId;
  final String? filePng;
  final String function;
  final String? side;
  final int? h;
  final int? w;

  CropSchematic({
    required this.id,
    required this.boardId,
    this.filePng,
    required this.function,
    this.side,
    this.h,
    this.w,
  });

  factory CropSchematic.fromJson(Map<String, dynamic> json) {
    return CropSchematic(
      id: json['id'] as int,
      boardId: json['board_id'] as int,
      filePng: json['file_png'] as String?,
      function: json['function'] as String,
      side: json['side'] as String?,
      h: json['h'] as int?,
      w: json['w'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'file_png': filePng,
      'function': function,
      'side': side,
      'h': h,
      'w': w,
    };
  }
}
