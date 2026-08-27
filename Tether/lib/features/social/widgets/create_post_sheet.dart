import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/feed_models.dart';
import '../services/social_service.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  final void Function(FeedPost post) onPostCreated;

  const CreatePostSheet({super.key, required this.onPostCreated});

  static Future<void> show(
    BuildContext context, {
    required void Function(FeedPost) onPostCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostSheet(onPostCreated: onPostCreated),
    );
  }

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _ctrl = TextEditingController();
  String _selectedType = 'announcement';
  bool _posting = false;
  String? _error;

  static const List<_PostType> _types = [
    _PostType('announcement', 'Announcement', Symbols.campaign),
    _PostType('class_update', 'Class Update', Symbols.schedule),
    _PostType('reminder', 'Reminder', Symbols.notifications_active),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write something first');
      return;
    }

    setState(() { _posting = true; _error = null; });
    try {
      final svc = ref.read(socialServiceProvider);
      final post = await svc.createStaffPost(
        type: _selectedType,
        content: text,
      );
      if (mounted) {
        widget.onPostCreated(post);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _posting = false;
          _error = 'Failed to post — you may not have staff permissions';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: 460 + keyboardPad,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: Text('POST ANNOUNCEMENT',
                style: Theme.of(context).textTheme.labelLarge)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Symbols.close, size: 18,
                    color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(
            children: _types.map((t) {
              final selected = t.value == _selectedType;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: t == _types.last ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryContainer.withOpacity(0.12)
                            : AppTheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryContainer.withOpacity(0.4)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon, size: 16,
                            color: selected
                                ? AppTheme.primaryContainer
                                : AppTheme.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text(t.label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                              color: selected
                                  ? AppTheme.primaryContainer
                                  : AppTheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Write your announcement...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.error)),
          ],

          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Post',
            icon: Symbols.send,
            isLoading: _posting,
            onPressed: _posting ? null : _post,
          ),
        ],
      ),
    );
  }
}

class _PostType {
  final String value;
  final String label;
  final IconData icon;
  const _PostType(this.value, this.label, this.icon);
}
