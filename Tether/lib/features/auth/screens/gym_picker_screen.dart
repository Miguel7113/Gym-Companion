import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../providers/gym_choice_provider.dart';
import '../widgets/auth_widgets.dart';
import 'sign_in_screen.dart';

class GymPickerScreen extends ConsumerStatefulWidget {
  const GymPickerScreen({super.key});

  @override
  ConsumerState<GymPickerScreen> createState() => _GymPickerScreenState();
}

class _GymPickerScreenState extends ConsumerState<GymPickerScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _select(Gym gym) async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    await rememberGym(ref, gym);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen(gym: gym)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final gymsAsync = ref.watch(gymsProvider);
    final lastGymId = ref.watch(lastGymIdProvider).valueOrNull;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AuthBackButton(),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.containerMargin,
                  AppTheme.stackMd,
                  AppTheme.containerMargin,
                  AppTheme.stackMd,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where do you\ntrain?',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: AppTheme.stackSm),
                      Text(
                        'Pick your gym to sign in. You can switch later.',
                        style: text.bodyLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppTheme.stackMd),
                      _SearchField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ),
              ...gymsAsync.when(
                loading: () => [const _LoadingList()],
                error: (_, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ConnectErrorState(
                      onRetry: () => ref.invalidate(gymsProvider),
                    ),
                  ),
                ],
                data: (gyms) => _results(gyms, lastGymId),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.stackLg + MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _results(List<Gym> gyms, String? lastGymId) {
    final matches = _query.isEmpty
        ? gyms
        : gyms.where((g) => g.name.toLowerCase().contains(_query)).toList();

    if (matches.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: gyms.isEmpty ? Symbols.fitness_center : Symbols.search_off,
            title: gyms.isEmpty
                ? 'No gyms yet'
                : 'No gym called "${_searchCtrl.text.trim()}"',
            message: 'Tether is set up by your gym. Ask the front desk if '
                'they use it.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
        sliver: SliverList.separated(
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final gym = matches[index];
            return _GymTile(
              gym: gym,
              isLast: gym.id == lastGymId,
              onTap: () => _select(gym),
            );
          },
        ),
      ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          borderSide: BorderSide(color: color, width: width),
        );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: text.bodyLarge,
        cursorColor: AppTheme.primaryContainer,
        decoration: InputDecoration(
          hintText: 'Search gyms',
          filled: true,
          fillColor: AppTheme.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(
            Symbols.search,
            size: 20,
            color: AppTheme.onSurfaceVariant,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Symbols.close, size: 18),
                  color: AppTheme.onSurfaceVariant,
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: border(Colors.white.withValues(alpha: 0.08)),
          enabledBorder: border(Colors.white.withValues(alpha: 0.08)),
          focusedBorder: border(AppTheme.primaryContainer, 1.5),
        ),
      ),
    );
  }
}

class _GymTile extends StatelessWidget {
  final Gym gym;
  final bool isLast;
  final VoidCallback onTap;

  const _GymTile({required this.gym, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = gymAccent(gym);

    return Material(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl + 2),
        side: BorderSide(
          color: isLast
              ? accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GymAvatar(gym: gym, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLast) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Last used on this phone',
                        style: text.bodySmall?.copyWith(color: accent),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Symbols.chevron_right,
                size: 22,
                color: AppTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
      sliver: SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => LayoutBuilder(
          builder: (context, constraints) => SkeletonBox(
            width: constraints.maxWidth,
            height: 76,
            radius: AppTheme.radiusXxl,
          ),
        ),
      ),
    );
  }
}
