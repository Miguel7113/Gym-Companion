import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/feed_models.dart';
import '../services/social_service.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  static Future<void> show(BuildContext context, {required String postId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(postId: postId),
    );
  }

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<FeedComment> _comments = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(socialServiceProvider);
      final comments = await svc.getComments(widget.postId);
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _posting) return;

    setState(() => _posting = true);
    try {
      final svc = ref.read(socialServiceProvider);
      final comment = await svc.createComment(widget.postId, text);
      if (mounted) {
        setState(() {
          _comments.add(comment);
          _posting = false;
        });
        _ctrl.clear();
        _focusNode.unfocus();
      }
    } catch (e) {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardPad,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(child: Text('COMMENTS',
                  style: Theme.of(context).textTheme.labelLarge)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Symbols.close, size: 18,
                      color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // Comments list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer)))
                : _comments.isEmpty
                    ? Center(
                        child: Text('No comments yet — be the first!',
                          style: Theme.of(context).textTheme.bodySmall))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _CommentTile(
                            comment: _comments[i]),
                      ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(
                  color: Colors.white.withOpacity(0.07))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _postComment,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonGlow(opacity: 0.3),
                    ),
                    child: _posting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  AppTheme.onPrimaryFixed)))
                        : const Icon(Symbols.send, size: 18,
                            color: AppTheme.onPrimaryFixed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final FeedComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceContainerHighest,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Symbols.person, size: 16,
                color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(comment.timeAgo,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.content,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
