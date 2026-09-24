import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../models/gym_notice.dart';
import '../providers/notices_provider.dart';

class CreateNoticeSheet extends ConsumerStatefulWidget {
  const CreateNoticeSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateNoticeSheet(),
    );
  }

  @override
  ConsumerState<CreateNoticeSheet> createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends ConsumerState<CreateNoticeSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _tag = 'ANNOUNCEMENT';
  bool _pinned = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and body are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(noticesProvider.notifier).create(
            title: title,
            body: body,
            tag: _tag,
            isPinned: _pinned,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed to post — coach permissions required';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppTheme.containerMargin,
          AppTheme.stackSm,
          AppTheme.containerMargin,
          bottom + AppTheme.stackMd,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'New notice',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shown on Home and Notices — not the feed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppTheme.stackMd),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kNoticeTags.map((tag) {
                  final selected = _tag == tag;
                  final label = tag == 'CLASS_UPDATE'
                      ? 'Class update'
                      : tag == 'ANNOUNCEMENT'
                          ? 'Announcement'
                          : tag == 'REMINDER'
                              ? 'Reminder'
                              : tag;
                  return ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: (_) => setState(() => _tag = tag),
                    selectedColor: AppTheme.primaryContainer.withOpacity(0.25),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryContainer
                          : AppTheme.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryContainer.withOpacity(0.5)
                          : Colors.white12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.stackSm),
              TextField(
                controller: _titleCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppTheme.stackSm),
              TextField(
                controller: _bodyCtrl,
                maxLines: 5,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  alignLabelWithHint: true,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin to top'),
                subtitle: Text(
                  'Pinned notices show first on Home',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                value: _pinned,
                activeColor: AppTheme.primaryContainer,
                onChanged: (v) => setState(() => _pinned = v),
              ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.error),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.campaign, size: 18),
                label: Text(_saving ? 'Posting…' : 'Post notice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
