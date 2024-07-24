class ChatroomMessageStruct {
  final int userId;
  final String message;
  final int id;
  final int createdAt;
  final int chatroomId;

  ChatroomMessageStruct({required this.userId, required this.message, required this.id, required this.createdAt, required this.chatroomId});

  factory ChatroomMessageStruct.fromMap(Map<String, dynamic> json) {
    return ChatroomMessageStruct(
      id: json['id'],
      userId: json['user_id'],
      message: json['message'],
      createdAt: json['created_at'],
      chatroomId: json['chatroom_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'message': message,
    };
  }
}
