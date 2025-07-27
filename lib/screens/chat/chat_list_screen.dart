import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/user_provider.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/models/user.dart'; // Import User model for other user's details

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedConversations = await ApiService.getConversations();
      setState(() {
        _conversations = fetchedConversations;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load conversations: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getOtherUserName(Map<String, dynamic> conversation) {
    final otherUser = conversation['other_user'] as Map<String, dynamic>?;
    return otherUser?['company'] ?? otherUser?['email'] ?? 'Unknown User';
  }

  String _getLastMessageContent(Map<String, dynamic> conversation) {
    final lastMessage = conversation['last_message'] as Map<String, dynamic>?;
    return lastMessage?['message'] ?? 'No messages yet';
  }

  DateTime _getLastMessageTime(Map<String, dynamic> conversation) {
    final lastMessage = conversation['last_message'] as Map<String, dynamic>?;
    return lastMessage != null ? DateTime.parse(lastMessage['timestamp']) : DateTime(2000); // Default old date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        child: _conversations.isEmpty
            ? const Center(
          child: Text('No conversations yet.'),
        )
            : ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final conversation = _conversations[index];
            final otherUserId = conversation['other_user_id'];
            final containerId = conversation['container_id'];
            final otherUserName = _getOtherUserName(conversation);
            final lastMessageContent = _getLastMessageContent(conversation);
            final lastMessageTime = _getLastMessageTime(conversation);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserName.substring(0, 1).toUpperCase()),
                ),
                title: Text(otherUserName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessageContent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (containerId != null)
                      Text(
                        'Container: ${containerId.substring(0, 8)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: Text(
                  '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  context.push(
                    '/chat/$otherUserId?containerId=${Uri.encodeComponent(containerId ?? '')}',
                    extra: {
                      'other_user_company': otherUserName,
                      'container_id': containerId,
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
