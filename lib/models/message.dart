import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id; // Firestore doc ID
  final String senderId;
  final String receiverId;
  final String message;
  final String? containerId; // Optional for general chat
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.containerId,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['sender_id'],
      receiverId: data['receiver_id'],
      message: data['message'],
      containerId: data['container_id'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
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
