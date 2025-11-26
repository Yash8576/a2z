import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reels screen for short-form video content
/// MAANG best practices:
/// - O(n) time where n = number of reels (paginated)
/// - O(1) space per reel in memory
/// - Vertical scrolling video feed like Instagram Reels/TikTok
class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reels'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query reels - O(n) where n = number of reels
        stream: FirebaseFirestore.instance
            .collection('reels')
            .orderBy('createdAt', descending: true)
            .limit(20) // Limit for performance
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reels',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final reels = snapshot.data?.docs ?? [];

          if (reels.isEmpty) {
            return _EmptyReelsView();
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index].data() as Map<String, dynamic>;
              return _ReelItem(
                reelId: reels[index].id,
                reel: reel,
                currentUserId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

/// Individual reel item widget
class _ReelItem extends StatelessWidget {
  final String reelId;
  final Map<String, dynamic> reel;
  final String currentUserId;

  const _ReelItem({
    required this.reelId,
    required this.reel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final userId = reel['userId'] ?? '';
    final caption = reel['caption'] ?? '';
    final likes = reel['likes'] ?? 0;
    final comments = reel['comments'] ?? 0;

    return Stack(
      children: [
        // Video placeholder (actual video player would go here)
        Container(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 80,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Gradient overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              // Like button
              _ActionButton(
                icon: Icons.favorite_border,
                label: likes.toString(),
                onTap: () {
                  // TODO: Implement like functionality
                },
              ),
              const SizedBox(height: 20),
              // Comment button
              _ActionButton(
                icon: Icons.comment_outlined,
                label: comments.toString(),
                onTap: () {
                  // TODO: Show comments
                },
              ),
              const SizedBox(height: 20),
              // Share button
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
        ),

        // Bottom user info and caption
        Positioned(
          bottom: 20,
          left: 12,
          right: 80,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final displayName = userData?['displayName'] ?? 'Unknown User';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Implement follow functionality
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        child: const Text('Follow'),
                      ),
                    ],
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Action button widget for reels
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty reels view
class _EmptyReelsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Reels Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start creating short videos to share',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_call),
              label: const Text('Create Reel'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create reel feature coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

