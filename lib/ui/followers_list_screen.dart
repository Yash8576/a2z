import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_view_screen.dart';
import 'profile_screen.dart';

/// Screen to display list of followers or following
/// MAANG best practices:
/// - O(n) where n = number of followers/following
/// - Real-time updates using StreamBuilder
/// - Efficient batch loading
class FollowersListScreen extends StatelessWidget {
  final String userId;
  final String listType; // 'followers' or 'following'
  final String displayName;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.listType,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final isFollowers = listType == 'followers';
    final title = isFollowers ? 'Followers' : 'Following';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('$displayName\'s $title'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
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
                  const Text('Error loading list'),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final listField = isFollowers ? 'followersList' : 'followingList';
          final userIdsList = List<String>.from(userData[listField] ?? []);

          if (userIdsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFollowers ? 'No followers yet' : 'Not following anyone yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userIdsList.length,
            itemBuilder: (context, index) {
              final targetUserId = userIdsList[index];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUserId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final targetUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final targetDisplayName = targetUserData['displayName'] ?? 'Unknown User';
                  final targetEmail = targetUserData['email'] ?? '';
                  final targetBio = targetUserData['bio'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          targetDisplayName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        targetDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        targetBio.isNotEmpty ? targetBio : targetEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // If it's current user, go to profile screen
                        // Otherwise go to user profile view screen
                        if (targetUserId == currentUserId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileViewScreen(
                                userId: targetUserId,
                                displayName: targetDisplayName,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

