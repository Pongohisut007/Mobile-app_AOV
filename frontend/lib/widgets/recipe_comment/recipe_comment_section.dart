import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_event.dart';
import 'package:flutter_application_1/bloc/recipe_comment/recipe_comment_state.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_comment.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/recipe_comment/recipe_comment_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipeCommentSection extends StatelessWidget {
  const RecipeCommentSection({
    super.key,
    this.headingKey,
    this.onReady,
    this.onCommentCountChanged,
  });

  final Key? headingKey;
  final VoidCallback? onReady;
  final ValueChanged<int>? onCommentCountChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipeCommentBloc, RecipeCommentState>(
      listenWhen: (previous, current) =>
          (previous.status != current.status &&
              current.status == RecipeCommentStatus.ready) ||
          (previous.submitStatus != current.submitStatus &&
              current.submitStatus == RecipeCommentSubmitStatus.success) ||
          (previous.mutationStatus != current.mutationStatus &&
              (current.mutationStatus == RecipeCommentMutationStatus.failure ||
                  (current.mutationStatus ==
                          RecipeCommentMutationStatus.success &&
                      current.mutationType ==
                          RecipeCommentMutationType.delete))),
      listener: (context, state) {
        if (state.status == RecipeCommentStatus.ready) onReady?.call();
        if (state.submitStatus == RecipeCommentSubmitStatus.success &&
            state.mutationType == RecipeCommentMutationType.submit) {
          onCommentCountChanged?.call(state.total);
        }
        if (state.mutationStatus == RecipeCommentMutationStatus.failure) {
          showAppSnackBar(
            context,
            state.error ?? 'ทำรายการไม่สำเร็จ',
            type: AppSnackType.error,
          );
        }
        if (state.mutationStatus == RecipeCommentMutationStatus.success &&
            state.mutationType == RecipeCommentMutationType.delete) {
          onCommentCountChanged?.call(state.total);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.status == RecipeCommentStatus.ready) ...[
              if (state.canComment)
                _InlineCommentComposer(
                  isSubmitting: state.isSubmitting,
                  submitStatus: state.submitStatus,
                  avatarUrl: state.userAvatarUrl,
                  onSubmit: (comment) => context.read<RecipeCommentBloc>().add(
                    RecipeCommentSubmitted(comment),
                  ),
                )
              else if (!state.isLoggedIn)
                // หน้าตาเหมือนตอน login แล้ว แต่กดส่งจะพาไป login ก่อน
                _InlineCommentComposer(
                  isSubmitting: false,
                  submitStatus: RecipeCommentSubmitStatus.idle,
                  avatarUrl: null,
                  onSubmit: (_) => _goToLogin(context),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'ซื้อสูตรนี้ก่อนจึงจะแสดงความคิดเห็นได้',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ความคิดเห็น',
                    key: headingKey,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${state.total}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.status == RecipeCommentStatus.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.status == RecipeCommentStatus.failure)
              _LoadError(
                message: state.error ?? 'โหลดความคิดเห็นไม่สำเร็จ',
                onRetry: () => context.read<RecipeCommentBloc>().add(
                  const RecipeCommentsRequested(),
                ),
              )
            else ...[
              if (state.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'ยังไม่มีความคิดเห็น',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else ...[
                for (final comment in state.comments) ...[
                  RecipeCommentTile(
                    comment: comment,
                    isOwner: comment.userId == state.userId,
                    isBusy: state.mutatingCommentId == comment.id,
                    // ระหว่างแก้ไข/ลบคอมเมนต์หนึ่งอยู่ ปิดเมนูของทุกคอมเมนต์
                    onEdit: state.isMutating
                        ? null
                        : () => _editComment(context, comment),
                    onDelete: state.isMutating
                        ? null
                        : () => _confirmDelete(context, comment),
                  ),
                  const SizedBox(height: 10),
                ],
                if (state.hasMore || state.isLoadingMore)
                  Center(
                    child: TextButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => context.read<RecipeCommentBloc>().add(
                              const RecipeCommentsMoreRequested(),
                            ),
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ดูความคิดเห็นเพิ่มเติม'),
                    ),
                  ),
                if (state.error != null && state.hasMore)
                  TextButton.icon(
                    onPressed: () => context.read<RecipeCommentBloc>().add(
                      const RecipeCommentsMoreRequested(),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('โหลดความคิดเห็นเพิ่มอีกครั้ง'),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _goToLogin(BuildContext context) {
    // กดส่งรัว ๆ ไม่ต้องเปิดหน้า login ซ้อน (เปิดไปแล้วหน้านี้จะไม่ใช่หน้าบนสุด)
    if (ModalRoute.of(context)?.isCurrent == false) return;
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  Future<void> _editComment(BuildContext context, RecipeComment comment) async {
    final updatedText = await showDialog<String>(
      context: context,
      builder: (_) => _EditRecipeCommentDialog(initialComment: comment.comment),
    );
    if (updatedText == null || !context.mounted) return;
    context.read<RecipeCommentBloc>().add(
      RecipeCommentUpdated(comment.id, updatedText),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecipeComment comment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบความคิดเห็น'),
        content: const Text('ต้องการลบความคิดเห็นนี้ใช่ไหม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<RecipeCommentBloc>().add(RecipeCommentDeleted(comment.id));
  }
}

class _EditRecipeCommentDialog extends StatefulWidget {
  const _EditRecipeCommentDialog({required this.initialComment});

  final String initialComment;

  @override
  State<_EditRecipeCommentDialog> createState() =>
      _EditRecipeCommentDialogState();
}

class _EditRecipeCommentDialogState extends State<_EditRecipeCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขความคิดเห็น'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 1000,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'เขียนความคิดเห็น',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

class _InlineCommentComposer extends StatefulWidget {
  const _InlineCommentComposer({
    required this.isSubmitting,
    required this.submitStatus,
    required this.avatarUrl,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final RecipeCommentSubmitStatus submitStatus;
  final String? avatarUrl;
  final ValueChanged<String> onSubmit;

  @override
  State<_InlineCommentComposer> createState() => _InlineCommentComposerState();
}

class _InlineCommentComposerState extends State<_InlineCommentComposer> {
  static const _maxCommentLength = 1000;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _InlineCommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submitStatus != RecipeCommentSubmitStatus.success &&
        widget.submitStatus == RecipeCommentSubmitStatus.success) {
      _controller.clear();
      _focusNode.unfocus();
      _expanded = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _expanded = false);
  }

  void _submit() {
    final comment = _controller.text.trim();
    if (comment.isEmpty || widget.isSubmitting) return;
    _focusNode.unfocus();
    widget.onSubmit(comment);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final resolvedAvatarUrl = _resolveAvatarUrl(
      widget.avatarUrl,
      ApiConfig.apiBaseUrl,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Colors.grey.shade200,
          foregroundImage: resolvedAvatarUrl == null
              ? null
              : appNetworkImageProvider(
                  context,
                  resolvedAvatarUrl,
                  logicalSize: 38,
                ),
          child: resolvedAvatarUrl == null
              ? Icon(Icons.person_outline, color: Colors.grey.shade700)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isSubmitting,
                minLines: 1,
                maxLines: _expanded ? 5 : 1,
                maxLength: _maxCommentLength,
                onTap: () => setState(() => _expanded = true),
                onChanged: (_) => setState(() => _expanded = true),
                decoration: InputDecoration(
                  hintText: 'เพิ่มความคิดเห็น...',
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6650A5)),
                  ),
                ),
              ),
              if (_expanded || hasText) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.isSubmitting ? null : _cancel,
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'ส่งความคิดเห็น',
                      onPressed: hasText && !widget.isSubmitting
                          ? _submit
                          : null,
                      icon: widget.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _resolveAvatarUrl(Object? value, String apiBaseUrl) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Expected an avatar URL string');
    }
    final url = value.trim();
    if (url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri?.hasScheme ?? false) return url;
    if (url.startsWith('//')) return '${Uri.parse(apiBaseUrl).scheme}:$url';

    final baseUrl = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$baseUrl${url.startsWith('/') ? url : '/$url'}';
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}
