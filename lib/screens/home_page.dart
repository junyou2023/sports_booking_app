import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/category_card.dart';
import '../widgets/activity_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  final categories = [
    {'label': 'Badminton',    'asset': 'assets/images/badminton.jpg'},
    {'label': 'Bungee Jump',  'asset': 'assets/images/bungee.jpg'},
    {'label': 'Sailing',      'asset': 'assets/images/sailing.jpg'},
    {'label': 'Cycling',      'asset': 'assets/images/cycling.jpg'},
  ];

  final activities = [
    {
      'title':    'Mountain Biking',
      'location': 'Rocky Hills',
      'price':    50.0,
      'rating':   4.8,
      'reviews':  230,
      'asset':    'assets/images/mountain_biking.jpg',
    },
    {
      'title':    'Kayaking Adventure',
      'location': 'Blue River',
      'price':    40.0,
      'rating':   4.6,
      'reviews':  145,
      'asset':    'assets/images/kayaking.jpg',
    },
    {
      'title':    'Paragliding',
      'location': 'Skyline Heights',
      'price':    120.0,
      'rating':   4.9,
      'reviews':  89,
      'asset':    'assets/images/paragliding.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Hero SliverAppBar
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/hero_banner.jpg',
                      fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black45, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: TextField(
              decoration: InputDecoration(
                hintText: 'Find places and things to do',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.tune),
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text('3',
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Discover 文案 + 按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Text(
                    'Discover things to do wherever you’re going',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(onPressed: () {}, child: Text('Learn more')),
                ],
              ),
            ),
          ),

          // 3. Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Text('Categories',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                padding: EdgeInsets.only(left: 16, right: 8),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 16),
                itemBuilder: (ctx, i) => CategoryCard(
                  title: categories[i]['label']!,
                  imageAsset: categories[i]['asset']!,
                  onTap: () {},
                ),
              ),
            ),
          ),

          // 4. Nearby Activities
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
              child: Text('Nearby Activities',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((_, idx) {
              final a = activities[idx];
              return ActivityCard(
                title:      a['title']! as String,
                location:   a['location']! as String,
                price:      (a['price'] as num).toDouble(),
                rating:     (a['rating'] as num).toDouble(),
                reviews:    (a['reviews'] as num).toInt(),
                imageAsset: a['asset']! as String,
                onTap:      () {},
              );
            }, childCount: activities.length),
          ),

          // 底部留空，防止被遮挡
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
