import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/support_request_model.dart';
import '../../services/message_service.dart';
import 'conversation_screen.dart';
import 'dart:async';

class CounsellorMessagesScreen extends StatefulWidget {
  const CounsellorMessagesScreen({super.key});

  @override
  State<CounsellorMessagesScreen> createState() =>
      _CounsellorMessagesScreenState();
}

class _CounsellorMessagesScreenState extends State<CounsellorMessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MessageService _messageService = MessageService();
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _listenToConversations();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _listenToConversations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in';
        _isLoading = false;
      });
      return;
    }

    // Listen to support requests assigned to this counsellor with conversation threads
    _requestsSubscription = _firestore
        .collection('support_requests')
        .where('counsellorId', isEqualTo: user.uid)
        .where(
          'status',
          whereIn: [
            SupportRequestStatus.accepted.name,
            SupportRequestStatus.inProgress.name,
          ],
        )
        .snapshots()
        .listen(
          (snapshot) async {
            // Fetch user details and unread count for each conversation
            final conversationsWithDetails = await Future.wait(
              snapshot.docs.map((doc) async {
                final request = SupportRequestModel.fromFirestore(doc);

                // Skip if no conversation thread
                if (request.conversationThreadId == null) {
                  return null;
                }

                final userDoc = await _firestore
                    .collection('users')
                    .doc(request.userId)
                    .get();

                // Get unread message count
                final unreadCount = await _messageService.getUnreadMessageCount(
                  request.conversationThreadId!,
                  user.uid,
                );

                // Get last message info from conversation thread
                final threadDoc = await _firestore
                    .collection('conversation_threads')
                    .doc(request.conversationThreadId)
                    .get();

                final lastMessageAt =
                    threadDoc.data()?['lastMessageAt'] as Timestamp?;

                return {
                  'request': request,
                  'userName': userDoc.data()?['name'] ?? 'Unknown User',
                  'userEmail': userDoc.data()?['email'] ?? '',
                  'unreadCount': unreadCount,
                  'lastMessageAt': lastMessageAt?.toDate(),
                };
              }),
            );

            // Filter out nulls and sort by last message time
            final validConversations = conversationsWithDetails
                .where((c) => c != null)
                .cast<Map<String, dynamic>>()
                .toList();

            validConversations.sort((a, b) {
              final aTime = a['lastMessageAt'] as DateTime?;
              final bTime = b['lastMessageAt'] as DateTime?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            setState(() {
              _conversations = validConversations;
              _isLoading = false;
              _errorMessage = null;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load conversations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No conversations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Accept support requests to start conversations.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final convData = _conversations[index];
        final request = convData['request'] as SupportRequestModel;
        final userName = convData['userName'] as String;
        final unreadCount = convData['unreadCount'] as int;
        final lastMessageAt = convData['lastMessageAt'] as DateTime?;

        return _buildConversationCard(
          request,
          userName,
          unreadCount,
          lastMessageAt,
        );
      },
    );
  }

  Widget _buildConversationCard(
    SupportRequestModel request,
    String userName,
    int unreadCount,
    DateTime? lastMessageAt,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          lastMessageAt != null
              ? _formatDate(lastMessageAt)
              : 'No messages yet',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          if (request.conversationThreadId == null) return;

          try {
            // Get conversation thread details
            final threadDoc = await _firestore
                .collection('conversation_threads')
                .doc(request.conversationThreadId)
                .get();

            if (!threadDoc.exists) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation not found'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final threadData = threadDoc.data()!;
            final otherUserId = threadData['userId'] as String;

            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ConversationScreen(
                    conversationThreadId: request.conversationThreadId!,
                    otherUserId: otherUserId,
                    otherUserName: userName,
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
