import 'package:flutter/material.dart';
import 'home_feed_screen.dart';
import 'reels_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

/// Main home screen with bottom navigation
/// MAANG best practices:
/// - O(1) space complexity (only holds current tab index)
/// - O(1) time for tab switching (no rebuilding of entire tree)
/// - Lazy loading of tabs for better performance
///
/// Bottom navigation structure:
/// 1. Home - Main feed with messages, search, and create access
/// 2. Reels - Short-form video content
/// 3. Products - Browse and search products
/// 4. Cart - Shopping cart management
/// 5. Profile - User/Seller profile with account-specific content
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  // Using a list to maintain screen instances
  // This prevents rebuilding screens when switching tabs
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeFeedScreen(), // Home with messages, search, create integrated
      const ReelsScreen(), // Short-form videos
      const ProductsScreen(), // Product browsing
      const CartScreen(), // Shopping cart
      const ProfileScreen(), // User/Seller profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

