import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool read;
  final MessageType type;
  final String? imageUrl;
  final String? audioUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.read = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp:
          map['timestamp'] != null
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      read: map['read'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'read': read,
      'type': type.name,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? read,
    MessageType? type,
    String? imageUrl,
    String? audioUrl,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

enum MessageType { text, image, audio, system }

// Classe pour les métadonnées de conversation
class ConversationMetadata {
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String lastSenderId;

  ConversationMetadata({
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.lastSenderId,
  });

  factory ConversationMetadata.fromMap(Map<String, dynamic> map) {
    return ConversationMetadata(
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          map['lastMessageTime'] != null
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      lastSenderId: map['lastSenderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'lastSenderId': lastSenderId,
    };
  }
}
