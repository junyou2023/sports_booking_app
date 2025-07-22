import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../providers.dart';
import 'activity_booking_page.dart';

class ActivityDetailPage extends ConsumerStatefulWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final commentCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.activity.imageUrl ?? widget.activity.image;
    final reviewsAsync = ref.watch(reviewsProvider(widget.activity.id));
    final authStatus = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.activity.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.activity.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${r'$'}${widget.activity.basePrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 4),
                Text('${widget.activity.duration} min'),
                const SizedBox(width: 16),
                const Icon(Icons.fitness_center, size: 20),
                const SizedBox(width: 4),
                Text('Level ${widget.activity.difficulty}'),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.activity.description),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final status = ref.read(authNotifierProvider);
                if (status != AuthStatus.authenticated) {
                  showAuthSheet(context);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityBookingPage(activity: widget.activity),
                  ),
                );
              },
              child: const Text('Book now'),
            ),
            const SizedBox(height: 24),
            Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Error: ${r'$'}e'),
              data: (List<Review> reviews) {
                if (reviews.isEmpty) {
                  return const Text('No reviews yet');
                }
                return Column(
                  children: reviews
                      .map(
                        (r) => ListTile(
                          title: Text(r.userEmail),
                          subtitle: Text(r.comment),
                          trailing: Text(r.rating.toString()),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            if (authStatus == AuthStatus.authenticated)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _rating,
                      decoration: const InputDecoration(labelText: 'Rating'),
                      items: List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (v) => setState(() => _rating = v ?? 1),
                    ),
                    TextFormField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(labelText: 'Comment'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _submitting = true);
                              try {
                                await ref
                                    .read(
                                      submitReviewProvider(
                                        ReviewSubmitData(
                                          activityId: widget.activity.id,
                                          rating: _rating,
                                          comment: commentCtrl.text,
                                        ),
                                      ).future,
                                    );
                                if (mounted) {
                                  commentCtrl.clear();
                                  setState(() => _rating = 5);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: ${r'$'}e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _submitting = false);
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Review'),
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
