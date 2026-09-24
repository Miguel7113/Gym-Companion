import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class CertifyQueueScreen extends ConsumerStatefulWidget {
  const CertifyQueueScreen({super.key});

  @override
  ConsumerState<CertifyQueueScreen> createState() => _CertifyQueueScreenState();
}

class _CertifyQueueScreenState extends ConsumerState<CertifyQueueScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/social/certify-queue');
    final data = response.data;
    if (data is! List) return [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _certify(String postId) async {
    final api = ref.read(apiClientProvider);
    await api.post('/social/posts/$postId/certify');
    if (!mounted) return;
    setState(() => _future = _load());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout certified')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Certify queue'),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load queue.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('No workouts waiting for certification.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.containerMargin),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final post = posts[index];
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['authorName']?.toString() ?? 'Member',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post['content']?.toString() ?? 'Completed workout',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _certify(post['id'] as String),
                        icon: const Icon(Symbols.verified, size: 18),
                        label: const Text('Certify'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
