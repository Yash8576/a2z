import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/local_media_storage.dart';

/// Chat screen for one-on-one conversations
/// MAANG best practices:
/// - O(n) time where n = number of messages displayed
/// - O(1) per message send operation
/// - Real-time updates using Firestore streams
/// - Efficient pagination for message history
class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _mediaStorage = LocalMediaStorage();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mark all messages in this conversation as read
  Future<void> _markMessagesAsRead() async {
    try {
      // Update conversation to mark messages as read
      await _firestore.collection('conversations').doc(widget.conversationId).update({
        'unreadCount_${_currentUser.uid}': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final messageData = {
        'senderId': _currentUser.uid,
        'receiverId': widget.otherUserId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text', // Message type
      };

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Add message to messages subcollection
      final messageRef = _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData);

      // Update conversation metadata
      final conversationRef =
          _firestore.collection('conversations').doc(widget.conversationId);
      batch.update(conversationRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUser.uid,
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });

      await batch.commit();

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Pick and send image
  Future<void> _sendImage() async {
    if (_isSending) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isSending = true);

      // Create message ID
      final messageRef = _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();
      final messageId = messageRef.id;

      // Save image locally
      final filePath = await _mediaStorage.saveMedia(
        messageId: messageId,
        conversationId: widget.conversationId,
        sourceFile: File(image.path),
        type: 'image',
        userId: _currentUser.uid,
      );

      // Send message with image reference
      final messageData = {
        'senderId': _currentUser.uid,
        'receiverId': widget.otherUserId,
        'text': '[Image]',
        'type': 'image',
        'mediaPath': filePath,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);

      final conversationRef =
          _firestore.collection('conversations').doc(widget.conversationId);
      batch.update(conversationRef, {
        'lastMessage': '📷 Image',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUser.uid,
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });

      await batch.commit();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Pick and send video
  Future<void> _sendVideo() async {
    if (_isSending) return;

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return;

      setState(() => _isSending = true);

      // Create message ID
      final messageRef = _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();
      final messageId = messageRef.id;

      // Save video locally
      final filePath = await _mediaStorage.saveMedia(
        messageId: messageId,
        conversationId: widget.conversationId,
        sourceFile: File(video.path),
        type: 'video',
        userId: _currentUser.uid,
      );

      // Send message with video reference
      final messageData = {
        'senderId': _currentUser.uid,
        'receiverId': widget.otherUserId,
        'text': '[Video]',
        'type': 'video',
        'mediaPath': filePath,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);

      final conversationRef =
          _firestore.collection('conversations').doc(widget.conversationId);
      batch.update(conversationRef, {
        'lastMessage': '🎥 Video',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUser.uid,
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });

      await batch.commit();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        const Text('Error loading messages'),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == _currentUser.uid;
                    final text = messageData['text'] ?? '';
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final messageType = messageData['type'] ?? 'text';
                    final mediaPath = messageData['mediaPath'] as String?;

                    return _MessageBubble(
                      messageId: messageDoc.id,
                      text: text,
                      isMe: isMe,
                      timestamp: timestamp,
                      messageType: messageType,
                      mediaPath: mediaPath,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  // Image picker button
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _isSending ? null : _sendImage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  // Video picker button
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: _isSending ? null : _sendVideo,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isMe;
  final Timestamp? timestamp;
  final String messageType;
  final String? mediaPath;

  const _MessageBubble({
    required this.messageId,
    required this.text,
    required this.isMe,
    this.timestamp,
    required this.messageType,
    this.mediaPath,
  });

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: messageType == 'text'
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display content based on message type
                  if (messageType == 'image' && mediaPath != null)
                    _ImageMessage(mediaPath: mediaPath!)
                  else if (messageType == 'video' && mediaPath != null)
                    _VideoMessage(mediaPath: mediaPath!)
                  else
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Image message widget
class _ImageMessage extends StatelessWidget {
  final String mediaPath;

  const _ImageMessage({required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open full screen image view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Center(
                child: Image.file(
                  File(mediaPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(mediaPath),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
        ),
      ),
    );
  }
}

/// Video message widget
class _VideoMessage extends StatelessWidget {
  final String mediaPath;

  const _VideoMessage({required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Open video player
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video player coming soon')),
        );
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(mediaPath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.videocam_off, size: 48),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

