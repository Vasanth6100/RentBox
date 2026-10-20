class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = true,
  });
}

class ChatConversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatConversation copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
