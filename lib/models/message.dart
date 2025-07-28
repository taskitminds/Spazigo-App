import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String? containerId;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.containerId,
    required this.timestamp,
  });

  // Factory for Firestore data
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['sender_id'],
      receiverId: data['receiver_id'],
      message: data['message'],
      containerId: data['container_id'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Factory for JSON data from PostgreSQL backend
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      containerId: json['container_id'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'container_id': containerId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}