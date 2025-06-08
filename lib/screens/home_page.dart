import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Banner with Search Box and Notifications
            Stack(
              children: [
                // Background Image
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/hero_banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Search Box and Notifications
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Search Box
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Find places and things to do',
                                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Notifications Button
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications, color: Colors.white),
                                onPressed: () {},
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Hero Text
                      const Text(
                        'Discover things to do wherever you\'re going',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Learn More Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Learn more'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryCard(context, 'Badminton', 'assets/images/badminton.jpg'),
                  _buildCategoryCard(context, 'Bungee Jump', 'assets/images/bungee.jpg'),
                  _buildCategoryCard(context, 'Sailing', 'assets/images/sailing.jpg'),
                  _buildCategoryCard(context, 'Cycling', 'assets/images/cycling.jpg'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Nearby Activities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Nearby Activities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityCard(
              context,
              'Mountain Biking',
              'Rocky Hills',
              '\$50',
              'assets/images/mountain_biking.jpg',
            ),
            _buildActivityCard(
              context,
              'Kayaking Adventure',
              'Blue River',
              '\$40',
              'assets/images/kayaking.jpg',
            ),
            _buildActivityCard(
              context,
              'Paragliding',
              'Skyline Heights',
              '\$120',
              'assets/images/paragliding.jpg',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, String title, String location, String price, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

