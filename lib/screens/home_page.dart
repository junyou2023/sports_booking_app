// ========== lib/screens/home_page.dart ==========
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/category_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  // ————— Fake Data —————
  final categories = [
    {'label': 'Badminton', 'asset': 'assets/images/badminton.jpg'},
    {'label': 'Bungee', 'asset': 'assets/images/bungee.jpg'},
    {'label': 'Sailing', 'asset': 'assets/images/sailing.jpg'},
    {'label': 'Cycling', 'asset': 'assets/images/cycling.jpg'},
  ];

  final activities = [
    {
      'title': 'Mountain Biking',
      'location': 'Rocky Hills',
      'price': 50.0,
      'rating': 4.8,
      'reviews': 230,
      'asset': 'assets/images/mountain_biking.jpg',
    },
    {
      'title': 'Kayaking Adventure',
      'location': 'Blue River',
      'price': 40.0,
      'rating': 4.6,
      'reviews': 145,
      'asset': 'assets/images/kayaking.jpg',
    },
  ];

  // ——————— UI ———————
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: _buildHome(context),
      ),
      bottomNavigationBar:
      AppBottomNav(index: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
    );
  }

  Widget _buildHome(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ——— 搜索栏 + Hero 图 ———
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.background,
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/stadium.jpg', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: RoundedSearchBar(onFilterTap: () {}),
            ),
          ),
        ),

        // ——— Learn More 按钮 ———
        SliverToBoxAdapter(
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text('Learn more'),
            ),
          ),
        ),

        // ——— Categories ———
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
          sliver: SliverToBoxAdapter(
            child: Text('Categories',
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 144,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => CategoryCard(
                title: categories[i]['label']!,
                asset: categories[i]['asset']!,
                onTap: () {},
              ),
            ),
          ),
        ),

        // ——— Nearby Activities ———
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
          sliver: SliverToBoxAdapter(
            child: Text('Nearby Activities',
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 310,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: activities.length,
              itemBuilder: (_, i) {
                final a = activities[i];
                return ActivityCard(
                  title: a['title'] as String,
                  location: a['location'] as String,
                  price: a['price'] as double,
                  rating: a['rating'] as double,
                  reviews: a['reviews'] as int,
                  asset: a['asset'] as String,
                  onTap: () {},
                );
              },
            ),
          ),
        ),

        // ——— Continue planning（示例：推荐项目） ———
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 32, 0, 0),
          sliver: SliverToBoxAdapter(
            child: Text('Continue planning',
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              scrollDirection: Axis.horizontal,
              children: [
                ProjectCard(
                    title: 'Sunset Sailing Tour',
                    imageUrl: 'assets/images/sailing.jpg',
                    onTap: () {}),
                const SizedBox(width: 20),
                ProjectCard(
                    title: 'Dolphin Watching',
                    imageUrl: 'assets/images/dolphin.jpg',
                    onTap: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
