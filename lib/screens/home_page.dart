// ========= lib/screens/home_page.dart =========
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';        // new
import 'package:sports_booking_app/screens/slots_page.dart';
import '../utils/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/category_card.dart';
import '../widgets/more_category_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';
import 'categories_page.dart';

import '../providers.dart';                                   // ← new (sportsProvider)
import '../providers/category_provider.dart';
import '../providers/activity_provider.dart';
import 'add_activity_page.dart';
import 'login_page.dart';                                     // for login navigation
import 'profile_page.dart';
import '../widgets/auth_sheet.dart';
import '../services/auth_service.dart';

class HomePage extends ConsumerStatefulWidget {               // Stateful → ConsumerStateful
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;


  @override
  Widget build(BuildContext context) {
    final double paddingTop = MediaQuery.of(context).padding.top;

    // ========== 监听 Provider ==========
    final categoriesAsync = ref.watch(categoriesProvider);
    final nearbyActsAsync = ref.watch(nearbyActivitiesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // ================= Hero + Search + Quick Filters（保持不变） =================
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 360,
            toolbarHeight: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (_, constraints) {
                final double h = constraints.biggest.height;
                final double opacity = ((h - 140) / 220).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Image.asset('assets/images/stadium.jpg', fit: BoxFit.cover),
                        Image.asset('assets/images/mountain.jpg', fit: BoxFit.cover),
                      ],
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
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
                            IconButton(
                              icon: const Icon(Icons.person_outline),
                              color: Colors.white,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              ),
                            ),
                            const _NotificationBell(count: 6),
                          ],
                        ),
                      ),
                    ),
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
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 90,
                      child: Text(
                        'Discover things to do\nwherever you’re going',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 6,
                        ),
                        onPressed: () {},
                        child: const Text('Learn more'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 72,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _QuickFilter(icon: Icons.auto_awesome,  label: 'For you'),
                            _QuickFilter(icon: Icons.account_balance, label: 'Culture'),
                            _QuickFilter(icon: Icons.restaurant, label: 'Food'),
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

          // ================= Categories（保持不变） =================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Categories', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          categoriesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load: $err'),
              ),
            ),
            data: (cats) {
              final top = cats.take(4).toList();
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: top.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      if (i < top.length) {
                        final c = top[i];
                        return CategoryCard(
                          title: c.name,
                          asset: c.icon,
                          imageUrl: c.imageUrl,
                          onTap: () {},
                        );
                      }
                      return MoreCategoryCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesPage(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // ─────────────────── Nearby Activities ───────────────────

// section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Nearby Activities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

// async list of activities → horizontal ActivityCard carousel
          nearbyActsAsync.when(
            // ❶ loading state
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

            // ❷ error state
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load activities: $err',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.red),
                ),
              ),
            ),

            // ❸ data state
            data: (acts) {
              if (acts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No nearby activities found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 310,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: acts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final act = acts[i];
                      return ActivityCard(
                        title: act.title,
                        location: '',
                        price: act.basePrice,
                        rating: 0,
                        reviews: 0,
                        asset: act.imageUrl ?? act.image,
                        isFavorite: false,
                        onFavorite: () {},
                        onTap: () {},
                      );
                    },
                  ),
                ),
              );
            },
          ),


          // ================= Continue planning（保持不变） =================
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
        onTap: (i) {
          if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityPage()),
          );
          if (created == true) {
            ref.invalidate(nearbyActivitiesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ======================== 小型私有组件（原样保留） ========================

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
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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