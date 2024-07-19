class ChatroomMessageStruct {
  final String userId;
  final String message;

  ChatroomMessageStruct({required this.userId, required this.message});

  factory ChatroomMessageStruct.fromMap(Map<String, dynamic> json) {
    return ChatroomMessageStruct(
      userId: json['user_id'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'message': message,
    };
  }
}
