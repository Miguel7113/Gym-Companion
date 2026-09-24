import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../social/services/social_extras_service.dart';
import '../widgets/directory_sheets.dart';

enum GymDirectoryTab { members, coaches }

class GymDirectoryScreen extends ConsumerStatefulWidget {
  const GymDirectoryScreen({
    super.key,
    this.initialTab = GymDirectoryTab.members,
  });

  final GymDirectoryTab initialTab;

  @override
  ConsumerState<GymDirectoryScreen> createState() => _GymDirectoryScreenState();
}

class _GymDirectoryScreenState extends ConsumerState<GymDirectoryScreen> {
  late GymDirectoryTab _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(homeMembersDirectoryProvider);
    ref.invalidate(homeCoachesProvider);
    await Future.wait([
      ref.read(homeMembersDirectoryProvider.future),
      ref.read(homeCoachesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(homeMembersDirectoryProvider);
    final coachesAsync = ref.watch(homeCoachesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Gym directory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.containerMargin,
              0,
              AppTheme.containerMargin,
              8,
            ),
            child: SegmentedButton<GymDirectoryTab>(
              segments: const [
                ButtonSegment(
                  value: GymDirectoryTab.members,
                  label: Text('Members'),
                  icon: Icon(Symbols.group, size: 18),
                ),
                ButtonSegment(
                  value: GymDirectoryTab.coaches,
                  label: Text('Coaches'),
                  icon: Icon(Symbols.sports, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          if (_tab == GymDirectoryTab.members)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                0,
                AppTheme.containerMargin,
                8,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search members',
                  prefixIcon: const Icon(Symbols.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Symbols.close),
                        ),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _tab == GymDirectoryTab.members
                  ? membersAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text("Couldn't load members: $e"),
                          ),
                        ],
                      ),
                      data: (members) {
                        final filtered = _query.isEmpty
                            ? members
                            : members
                                .where(
                                  (m) => m.displayName
                                      .toLowerCase()
                                      .contains(_query),
                                )
                                .toList();
                        if (filtered.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No members to show yet')),
                            ],
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.containerMargin),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            return GlassCard(
                              onTap: () => showMemberDirectorySheet(
                                context,
                                member: m,
                              ),
                              child: Row(
                                children: [
                                  _DirAvatar(
                                    name: m.displayName,
                                    isTrainingNow: m.isTrainingNow,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          m.isTrainingNow
                                              ? 'Training now'
                                              : _buddyCaption(m.buddyStatus),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: m.isTrainingNow
                                                    ? AppTheme.primaryContainer
                                                    : AppTheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Symbols.chevron_right,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  : coachesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text("Couldn't load coaches: $e"),
                          ),
                        ],
                      ),
                      data: (coaches) {
                        if (coaches.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No coaches listed yet.\nAsk your gym to invite a coach.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.containerMargin),
                          itemCount: coaches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final c = coaches[i];
                            final role = c.role.toLowerCase() == 'admin'
                                ? 'Admin'
                                : 'Coach';
                            return GlassCard(
                              onTap: () => showCoachDirectorySheet(
                                context,
                                coach: c,
                              ),
                              child: Row(
                                children: [
                                  _DirAvatar(
                                    name: c.displayName,
                                    isTrainingNow: c.isTrainingNow,
                                    accent: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          c.isTrainingNow
                                              ? '$role · Training now'
                                              : '$role · ${c.programCount} programs',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Symbols.chevron_right,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _buddyCaption(String status) {
    switch (status) {
      case 'active':
        return 'Gym buddy';
      case 'pending_outgoing':
        return 'Request sent';
      case 'pending_incoming':
        return 'Incoming request';
      default:
        return 'Member';
    }
  }
}

class _DirAvatar extends StatelessWidget {
  const _DirAvatar({
    required this.name,
    this.isTrainingNow = false,
    this.accent = false,
  });

  final String name;
  final bool isTrainingNow;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accent
              ? AppTheme.primaryContainer.withValues(alpha: 0.16)
              : AppTheme.surfaceContainerHigh,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: accent ? AppTheme.primaryContainer : AppTheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isTrainingNow)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceContainer, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
