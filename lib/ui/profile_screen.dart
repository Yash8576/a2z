import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'followers_list_screen.dart';

/// Profile screen showing user information and content
/// MAANG best practices:
/// - O(1) space complexity for user data display
/// - O(1) time per Firestore update via stream
/// - Efficient real-time updates using StreamBuilder
///
/// Account Types:
/// 1. Consumer/Normal Account: photos, videos, orders, following count
/// 2. Seller Account: photos, videos, products, NO following count
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userRepo = UserRepository();
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: userRepo.userStream(user.uid),
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
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data ?? {};
          final displayName = userData['displayName'] ?? user.email?.split('@')[0] ?? 'User';
          final email = userData['email'] ?? user.email ?? '';
          final bio = userData['bio'] ?? 'No bio yet';
          final isSeller = userData['accountType'] == 'seller';
          final followers = userData['followers'] ?? 0;
          final following = userData['following'] ?? 0;

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
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20),
                                color: Theme.of(context).colorScheme.onSecondary,
                                onPressed: () {
                                  // TODO: Implement image picker for local storage
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Image upload will be stored locally (coming soon)'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
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
                      // Stats row - different for consumer vs seller
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: StreamBuilder<QuerySnapshot>(
                          // Get counts for posts/products
                          stream: FirebaseFirestore.instance
                              .collection(isSeller ? 'posts' : 'posts')
                              .where('userId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, postsSnapshot) {
                            final photosVideosCount = postsSnapshot.data?.docs.length ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream: isSeller
                                  ? FirebaseFirestore.instance
                                      .collection('products')
                                      .where('sellerId', isEqualTo: user.uid)
                                      .snapshots()
                                  : FirebaseFirestore.instance
                                      .collection('orders')
                                      .where('userId', isEqualTo: user.uid)
                                      .where('status', isEqualTo: 'completed')
                                      .snapshots(),
                              builder: (context, extraSnapshot) {
                                final extraCount = extraSnapshot.data?.docs.length ?? 0;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatItem(
                                      label: 'Posts',
                                      value: photosVideosCount.toString(),
                                      onTap: () {},
                                    ),
                                    _StatItem(
                                      label: 'Followers',
                                      value: followers.toString(),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowersListScreen(
                                              userId: user.uid,
                                              listType: 'followers',
                                              displayName: displayName,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (!isSeller)
                                      _StatItem(
                                        label: 'Following',
                                        value: following.toString(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FollowersListScreen(
                                                userId: user.uid,
                                                listType: 'following',
                                                displayName: displayName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    if (isSeller)
                                      _StatItem(
                                        label: 'Products',
                                        value: extraCount.toString(),
                                        onTap: () {
                                          // TODO: Navigate to products list
                                        },
                                      ),
                                    if (!isSeller)
                                      _StatItem(
                                        label: 'Orders',
                                        value: extraCount.toString(),
                                        onTap: () {
                                          // TODO: Navigate to orders list
                                        },
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Edit profile button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(
                                    currentData: userData,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Tabs for content - different for consumer vs seller
                DefaultTabController(
                  length: isSeller ? 3 : 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          const Tab(icon: Icon(Icons.grid_on), text: 'Photos'),
                          const Tab(icon: Icon(Icons.video_library), text: 'Videos'),
                          Tab(
                            icon: Icon(isSeller ? Icons.shopping_bag : Icons.shopping_basket),
                            text: isSeller ? 'Products' : 'Orders',
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          children: [
                            // Photos tab
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('userId', isEqualTo: user.uid)
                                  .where('type', isEqualTo: 'photo')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final photos = snapshot.data?.docs ?? [];
                                if (photos.isEmpty) {
                                  return const _EmptyContentView(
                                    icon: Icons.photo_library,
                                    message: 'No photos yet',
                                    subtitle: 'Start sharing your photos',
                                  );
                                }
                                return GridView.builder(
                                  padding: const EdgeInsets.all(4),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: photos.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image, color: Colors.grey.shade400),
                                    );
                                  },
                                );
                              },
                            ),
                            // Videos tab
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('userId', isEqualTo: user.uid)
                                  .where('type', isEqualTo: 'video')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final videos = snapshot.data?.docs ?? [];
                                if (videos.isEmpty) {
                                  return const _EmptyContentView(
                                    icon: Icons.video_library,
                                    message: 'No videos yet',
                                    subtitle: 'Upload videos to share with others',
                                  );
                                }
                                return GridView.builder(
                                  padding: const EdgeInsets.all(4),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: videos.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.play_circle, color: Colors.grey.shade400),
                                    );
                                  },
                                );
                              },
                            ),
                            // Products/Orders tab
                            if (isSeller)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('products')
                                    .where('sellerId', isEqualTo: user.uid)
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final products = snapshot.data?.docs ?? [];
                                  if (products.isEmpty) {
                                    return const _EmptyContentView(
                                      icon: Icons.shopping_bag,
                                      message: 'No products yet',
                                      subtitle: 'Start adding products to sell',
                                    );
                                  }
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(4),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index].data() as Map<String, dynamic>;
                                      final title = product['title'] ?? 'Product';
                                      final price = product['price'] ?? 0.0;
                                      return Card(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                color: Colors.grey.shade200,
                                                child: Icon(Icons.image, color: Colors.grey.shade400),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text('\$$price'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            else
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('orders')
                                    .where('userId', isEqualTo: user.uid)
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final orders = snapshot.data?.docs ?? [];
                                  if (orders.isEmpty) {
                                    return const _EmptyContentView(
                                      icon: Icons.shopping_basket,
                                      message: 'No orders yet',
                                      subtitle: 'Your orders will appear here',
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: orders.length,
                                    itemBuilder: (context, index) {
                                      final order = orders[index].data() as Map<String, dynamic>;
                                      final orderId = orders[index].id;
                                      final status = order['status'] ?? 'pending';
                                      final total = order['total'] ?? 0.0;
                                      return Card(
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.shopping_bag,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          title: Text('Order #${orderId.substring(0, 8)}'),
                                          subtitle: Text('Status: $status'),
                                          trailing: Text(
                                            '\$$total',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
      floatingActionButton: StreamBuilder<Map<String, dynamic>?>(
        stream: userRepo.userStream(user.uid),
        builder: (context, snapshot) {
          final userData = snapshot.data ?? {};
          final isSeller = userData['accountType'] == 'seller';

          return FloatingActionButton(
            onPressed: () {
              _showCreateOptions(context, isSeller);
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  /// Show create options based on account type
  static void _showCreateOptions(BuildContext context, bool isSeller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Common options for both account types
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Create Post'),
              subtitle: const Text('Share a photo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create post feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Create Reel'),
              subtitle: const Text('Share a short video'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create reel feature coming soon')),
                );
              },
            ),
            // Seller-only option
            if (isSeller)
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.green),
                title: const Text('Add Product'),
                subtitle: const Text('List a product for sale'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add product feature coming soon')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Stat item widget for followers, following, posts
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget for content views
class _EmptyContentView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyContentView({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }
}

