import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class GymSelectionScreen extends ConsumerStatefulWidget {
  const GymSelectionScreen({super.key});

  @override
  ConsumerState<GymSelectionScreen> createState() => _GymSelectionScreenState();
}

class _GymSelectionScreenState extends ConsumerState<GymSelectionScreen> {
  final _searchController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isSearching = false;
  List<Gym> _results = [];
  String? _error;

  Future<void> _searchByName(String query) async {
    if (query.trim().length < 2) return;
    setState(() { _isSearching = true; _error = null; });
    try {
      final service = ref.read(authServiceProvider);
      final gyms = await service.searchGyms(name: query);
      setState(() { _results = gyms; });
    } catch (e) {
      setState(() { _error = 'Search failed: \$e'; });
    } finally {
      setState(() { _isSearching = false; });
    }
  }

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _isSearching = true; _error = null; _results = []; });
    try {
      final service = ref.read(authServiceProvider);
      final gyms = await service.searchGyms(code: code);
      if (gyms.isEmpty) {
        setState(() { _error = 'No gym found with code: \$code'; });
      } else {
        setState(() { _results = gyms; });
      }
    } catch (e) {
      setState(() { _error = 'Search failed: \$e'; });
    } finally {
      setState(() { _isSearching = false; });
    }
  }

  void _selectGym(Gym gym) {
    ref.read(authNotifierProvider.notifier).selectGym(gym);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OtpRequestScreen()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Find Your Gym',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your gym code or search by name',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Gym Code Input
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Gym Code',
                  hintText: 'e.g. IRONPUMP2024',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _searchByCode,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _searchByCode(),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2))),
                ],
              ),
              const SizedBox(height: 16),

              // Name Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by gym name',
                  hintText: 'Start typing...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.trim().length >= 3) {
                    _searchByName(value);
                  }
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final gym = _results[index];
                      return _GymCard(
                        gym: gym,
                        onTap: () => _selectGym(gym),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;

  const _GymCard({required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(
      int.parse(gym.primaryColor.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: gym.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(gym.logoUrl!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.fitness_center, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gym.code,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// Forward declaration so GymSelectionScreen can navigate to it
class OtpRequestScreen extends StatelessWidget {
  const OtpRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => const Placeholder();
}
