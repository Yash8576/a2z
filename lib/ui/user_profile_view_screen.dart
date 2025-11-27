import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'followers_list_screen.dart';
import 'chat_screen.dart';

/// User Profile View Screen - for viewing OTHER users' profiles
/// Includes follow/unfollow functionality
/// MAANG best practices:
/// - O(1) follow/unfollow operations
/// - Real-time updates using StreamBuilder
/// - Transaction-based follower count updates for consistency
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final currentUserDoc = await _firestore.collection('users').doc(_currentUser.uid).get();
      final followingList = List<String>.from(currentUserDoc.data()?['followingList'] ?? []);
      setState(() {
        _isFollowing = followingList.contains(widget.userId);
      });
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final currentUserRef = _firestore.collection('users').doc(_currentUser.uid);
      final targetUserRef = _firestore.collection('users').doc(widget.userId);

      if (_isFollowing) {
        // Unfollow
        await _firestore.runTransaction((transaction) async {
          // Remove from current user's following list
          transaction.update(currentUserRef, {
            'followingList': FieldValue.arrayRemove([widget.userId]),
            'following': FieldValue.increment(-1),
          });

          // Remove from target user's followers list
          transaction.update(targetUserRef, {
            'followersList': FieldValue.arrayRemove([_currentUser.uid]),
            'followers': FieldValue.increment(-1),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed ${widget.displayName}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Follow
        await _firestore.runTransaction((transaction) async {
          // Add to current user's following list
          transaction.update(currentUserRef, {
            'followingList': FieldValue.arrayUnion([widget.userId]),
            'following': FieldValue.increment(1),
          });

          // Add to target user's followers list
          transaction.update(targetUserRef, {
            'followersList': FieldValue.arrayUnion([_currentUser.uid]),
            'followers': FieldValue.increment(1),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Following ${widget.displayName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }

      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Open or create a conversation with this user
  Future<void> _openChat(BuildContext context, String otherUserName) async {
    try {
      // Create conversation ID (always use same format for consistency)
      final participants = [_currentUser.uid, widget.userId]..sort();
      final conversationId = participants.join('_');

      // Check if conversation exists, if not create it
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) {
        // Create new conversation
        await conversationRef.set({
          'participants': participants,
          'participantNames': {
            _currentUser.uid: _currentUser.displayName ?? _currentUser.email?.split('@')[0] ?? 'User',
            widget.userId: otherUserName,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCount_${_currentUser.uid}': 0,
          'unreadCount_${widget.userId}': 0,
        });
      }

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: widget.userId,
              otherUserName: otherUserName,
              conversationId: conversationId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Error loading profile'),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final displayName = userData['displayName'] ?? 'Unknown User';
          final email = userData['email'] ?? '';
          final bio = userData['bio'] ?? 'No bio yet';
          final followers = userData['followers'] ?? 0;
          final following = userData['following'] ?? 0;
          final isSeller = userData['accountType'] == 'seller';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Profile picture
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Display name
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Account type badge
                      if (isSeller)
                        Chip(
                          avatar: const Icon(Icons.store, size: 16),
                          label: const Text('Seller Account'),
                          backgroundColor: Colors.amber.shade100,
                        ),
                      const SizedBox(height: 16),
                      // Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          bio,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats row - matching own profile stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: StreamBuilder<QuerySnapshot>(
                          // Get counts for posts
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .where('userId', isEqualTo: widget.userId)
                              .snapshots(),
                          builder: (context, postsSnapshot) {
                            final postsCount = postsSnapshot.data?.docs.length ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream: isSeller
                                  ? FirebaseFirestore.instance
                                      .collection('products')
                                      .where('sellerId', isEqualTo: widget.userId)
                                      .snapshots()
                                  : FirebaseFirestore.instance
                                      .collection('orders')
                                      .where('userId', isEqualTo: widget.userId)
                                      .where('status', isEqualTo: 'completed')
                                      .snapshots(),
                              builder: (context, extraSnapshot) {
                                final extraCount = extraSnapshot.data?.docs.length ?? 0;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatColumn(
                                      label: 'Posts',
                                      value: postsCount.toString(),
                                      onTap: null,
                                    ),
                                    _StatColumn(
                                      label: 'Followers',
                                      value: followers.toString(),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowersListScreen(
                                              userId: widget.userId,
                                              listType: 'followers',
                                              displayName: displayName,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (!isSeller)
                                      _StatColumn(
                                        label: 'Following',
                                        value: following.toString(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FollowersListScreen(
                                                userId: widget.userId,
                                                listType: 'following',
                                                displayName: displayName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    if (isSeller)
                                      _StatColumn(
                                        label: 'Products',
                                        value: extraCount.toString(),
                                        onTap: null,
                                      ),
                                    if (!isSeller)
                                      _StatColumn(
                                        label: 'Orders',
                                        value: extraCount.toString(),
                                        onTap: null,
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Follow/Unfollow and Message buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            // Follow/Unfollow button
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? Colors.grey.shade300
                                        : Theme.of(context).colorScheme.primary,
                                    foregroundColor: _isFollowing
                                        ? Colors.black87
                                        : Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                                  label: Text(
                                    _isFollowing ? 'Unfollow' : 'Follow',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Message button
                            SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () => _openChat(context, displayName),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                ),
                                icon: const Icon(Icons.message),
                                label: const Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Bio section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(height: 32),
                      // Content tabs placeholder
                      Text(
                        isSeller ? 'Products' : 'Posts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              isSeller ? Icons.shopping_bag : Icons.photo_library,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isSeller ? 'No products yet' : 'No posts yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatColumn({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      );
    }

    return child;
  }
}

