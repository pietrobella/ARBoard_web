class UserManual {
  final int id;
  final int boardId;
  final String? filePdf;

  UserManual({required this.id, required this.boardId, this.filePdf});

  factory UserManual.fromJson(Map<String, dynamic> json) {
    return UserManual(
      id: json['id'] as int,
      boardId: json['board_id'] as int,
      filePdf: json['file_pdf'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'board_id': boardId, 'file_pdf': filePdf};
  }
}
