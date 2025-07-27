import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/models/message.dart';
import 'package:spazigo/providers/user_provider.dart';
import 'package:spazigo/services/api_service.dart'; // For sending message via REST (optional if Firestore is primary)
import 'package:uuid/uuid.dart'; // For generating unique IDs for local messages

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String? containerId; // Optional for container-specific chat
  final String? otherUserCompanyName; // For display purpose

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    this.containerId,
    this.otherUserCompanyName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  late String _currentUserId;
  late String _chatId; // A deterministic chat ID for Firestore

  @override
  void initState() {
    super.initState();
    _currentUserId = Provider.of<UserProvider>(context, listen: false).user!.id;
    _chatId = _getChatId(_currentUserId, widget.otherUserId, widget.containerId);

    // Scroll to bottom when keyboard appears or new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // At bottom
        }
      });
    });
  }

  // Generate a deterministic chat ID based on participants and optional container
  String _getChatId(String user1, String user2, String? containerId) {
    // Sort user IDs to ensure consistent chat ID regardless of who initiates
    final participants = [user1, user2]..sort();
    String baseId = '${participants[0]}_${participants[1]}';
    if (containerId != null && containerId.isNotEmpty) {
      baseId = '${baseId}_$containerId';
    }
    return baseId; // Simple concatenation for chat ID
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear(); // Clear input immediately

    // Add message to Firestore (for real-time display)
    final newMessage = Message(
      id: _uuid.v4(), // Generate temporary ID for local display
      senderId: _currentUserId,
      receiverId: widget.otherUserId,
      message: messageText,
      containerId: widget.containerId,
      timestamp: DateTime.now(),
    );

    // Save to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(newMessage.toFirestore());

      // Also send to backend REST API (for persistence in PostgreSQL)
      await ApiService.sendMessage(
        widget.otherUserId,
        messageText,
        containerId: widget.containerId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      debugPrint('Error sending message: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserCompanyName ?? 'Chat with Other User'),
            if (widget.containerId != null)
              Text(
                'Container: ${widget.containerId!.substring(0, 8)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Start a conversation!'));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey[700],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          message.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}