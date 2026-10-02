import 'package:flutter/material.dart';
import 'package:flutter_application_1/repositories/chat_repository.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

class ChatBubbleMessage {
  const ChatBubbleMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// แชทที่แสดงในแอป ต้องตรงกับที่ backend จำไว้
class RecipeChatHistory {
  // ต้องตรงกับ SESSION_TIMEOUT_MS ใน backend
  static const sessionTimeout = Duration(minutes: 20);

  final List<ChatBubbleMessage> messages = [];
  DateTime? _lastActiveAt;

  /// backend ลืมแชทไปแล้ว ฝั่งแอปก็ล้างตาม
  void clearIfExpired() {
    final last = _lastActiveAt;
    if (last != null && DateTime.now().difference(last) > sessionTimeout) {
      clear();
    }
  }

  void add(ChatBubbleMessage message) {
    messages.add(message);
    _lastActiveAt = DateTime.now();
  }

  void clear() {
    messages.clear();
    _lastActiveAt = null;
  }
}

/// popup แชทถาม AI เกี่ยวกับสูตร
class RecipeChatSheet extends StatefulWidget {
  const RecipeChatSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.recipeId,
    required this.history,
  });

  final ChatRepository repository;
  final String accessToken;
  final String recipeId;
  final RecipeChatHistory history;

  @override
  State<RecipeChatSheet> createState() => _RecipeChatSheetState();
}

class _RecipeChatSheetState extends State<RecipeChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isSending = false;

  List<ChatBubbleMessage> get _messages => widget.history.messages;

  @override
  void initState() {
    super.initState();
    widget.history.clearIfExpired();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() {
      widget.history.add(ChatBubbleMessage(text: text, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await widget.repository.sendMessage(
        widget.accessToken,
        widget.recipeId,
        text,
      );
      widget.history.add(ChatBubbleMessage(text: reply, isUser: false));
    } catch (error) {
      // ส่งไม่สำเร็จ เอาคำถามคืนไปไว้ในช่องพิมพ์ ให้กดส่งใหม่ได้
      _messages.removeLast();
      _inputController.text = text;
      _showError(error);
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _reset() async {
    try {
      await widget.repository.reset(widget.accessToken);
      setState(widget.history.clear);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ดันขึ้นตามคีย์บอร์ด
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty ? _buildEmpty() : _buildMessages(),
            ),
            if (_isSending) _buildTyping(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: FoodDetailColors.purple,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ถาม AI เกี่ยวกับสูตรนี้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'เริ่มแชทใหม่',
            onPressed: _isSending || _messages.isEmpty ? null : _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'ปิด',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'ถามอะไรก็ได้เกี่ยวกับสูตรนี้\nเช่น "ใช้อะไรแทนน้ำปลาได้บ้าง"',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'AI กำลังพิมพ์...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                maxLength: 4000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'พิมพ์คำถาม...',
                  counterText: '',
                  filled: true,
                  fillColor: FoodDetailColors.softPurple,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _isSending ? null : _send,
              color: FoodDetailColors.purple,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatBubbleMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? FoodDetailColors.purple : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
