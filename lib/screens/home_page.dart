// ========= lib/screens/home_page.dart =========
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/category_card.dart';
import '../widgets/more_category_card.dart';   // 新增
import '../widgets/activity_card.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';
import 'categories_page.dart';                // 新增

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  //-- 全量类别数据 -----------------------------------------------------------------
  final List<Map<String, String>> _allCategories = [
    {'label': 'Badminton', 'asset': 'assets/images/badminton.jpg'},
    {'label': 'Bungee',    'asset': 'assets/images/bungee.jpg'},
    {'label': 'Sailing',   'asset': 'assets/images/sailing.jpg'},
    {'label': 'Cycling',   'asset': 'assets/images/cycling.jpg'},
    {'label': 'Hiking',    'asset': 'assets/images/hiking.jpg'},
    {'label': 'Surfing',   'asset': 'assets/images/surfing.jpg'},
  ];

  // 首页只展示前 4 个
  List<Map<String, String>> get _topCategories =>
      _allCategories.take(4).toList();

  //-- Demo Activities -------------------------------------------------------------
  final List<Map<String, dynamic>> _activities = [
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
  ];

  @override
  Widget build(BuildContext context) {
    final double paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // ======================== Hero 区域 ========================
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 360,
            toolbarHeight: 0,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (_, constraints) {
                final double currentHeight = constraints.biggest.height;
                final double opacity =
                ((currentHeight - 140) / 220).clamp(0.0, 1.0).toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景图 PageView
                    PageView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Image.asset('assets/images/stadium.jpg',
                            fit: BoxFit.cover),
                        Image.asset('assets/images/mountain.jpg',
                            fit: BoxFit.cover),
                      ],
                    ),
                    // 顶部渐变，保证状态栏可读
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                    // 搜索框 + 通知铃
                    Positioned(
                      top: paddingTop + 16,
                      left: 16,
                      right: 16,
                      child: Opacity(
                        opacity: opacity,
                        child: Row(
                          children: [
                            const Expanded(child: RoundedSearchBar()),
                            const SizedBox(width: 12),
                            const _NotificationBell(count: 6),
                          ],
                        ),
                      ),
                    ),
                    // 文字区暗面
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: 140,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),
                    // 标题
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 90,
                      child: Text(
                        'Discover things to do\nwherever you’re going',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // CTA
                    Positioned(
                      left: 16,
                      bottom: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 6,
                        ),
                        onPressed: () {},
                        child: const Text('Learn more'),
                      ),
                    ),
                    // 四个快速过滤标签
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 72,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _QuickFilter(
                                icon: Icons.auto_awesome, label: 'For you'),
                            _QuickFilter(
                                icon: Icons.account_balance, label: 'Culture'),
                            _QuickFilter(
                                icon: Icons.restaurant, label: 'Food'),
                            _QuickFilter(icon: Icons.terrain, label: 'Nature'),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ======================== Categories ========================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                scrollDirection: Axis.horizontal,
                itemCount: _topCategories.length + 1, // +1 为 “More”
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  if (i < _topCategories.length) {
                    // 普通类别卡片
                    return CategoryCard(
                      title: _topCategories[i]['label']!,
                      asset: _topCategories[i]['asset']!,
                      onTap: () {
                        // TODO: 跳到具体分类详情
                      },
                    );
                  }
                  // “More” 卡片
                  return MoreCategoryCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoriesPage(allCategories: _allCategories),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ======================== Nearby Activities ========================
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
                itemCount: _activities.length,
                itemBuilder: (_, i) {
                  final a = _activities[i];
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

          // ======================== Continue planning ========================
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
                    onTap: () {},
                  ),
                  const SizedBox(width: 20),
                  ProjectCard(
                    title: 'Dolphin Watching',
                    imageUrl: 'assets/images/dolphin.jpg',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ======================= 私有组件 =======================

/// 顶部通知铃 + 小红点
class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24),
            onPressed: () {},
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hero 底部快速过滤
class _QuickFilter extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickFilter({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white),
        )
      ],
    );
  }
}
