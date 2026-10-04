import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/repositories/chat_repository.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:image_picker/image_picker.dart';

class ChatBubbleMessage {
  const ChatBubbleMessage({
    required this.text,
    required this.isUser,
    this.imageBytes,
  });

  final String text;
  final bool isUser;
  // รูปที่ผู้ใช้แนบ (เก็บไว้แสดงในแอปเท่านั้น backend ไม่ได้เก็บรูป)
  final Uint8List? imageBytes;
}

/// แชทที่แสดงในแอป ต้องตรงกับที่ backend จำไว้
class RecipeChatHistory {
  // ต้องตรงกับ SESSION_TTL_SECONDS ใน backend
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
  final _picker = ImagePicker();

  bool _isSending = false;
  bool _isResetting = false;
  bool _isLoadingHistory = false;
  // รูปที่เลือกไว้ รอส่งพร้อมคำถาม
  ChatImage? _image;
  // ข้อผิดพลาดล่าสุด แสดงในชีตเอง เพราะ SnackBar จะไปโผล่หลังชีตจนมองไม่เห็น
  String? _errorText;

  List<ChatBubbleMessage> get _messages => widget.history.messages;

  @override
  void initState() {
    super.initState();
    widget.history.clearIfExpired();
    // ออกจากหน้าสูตรแล้วกลับมา แชทในแอปหายไป แต่ backend ยังจำอยู่ เลยโหลดกลับมา
    if (_messages.isEmpty) {
      _isLoadingHistory = true;
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await widget.repository.fetchHistory(
        widget.accessToken,
        widget.recipeId,
      );
      // ระหว่างโหลด ผู้ใช้อาจพิมพ์ส่งไปแล้ว ไม่ต้องทับ
      if (_messages.isEmpty) {
        for (final entry in entries) {
          widget.history.add(
            ChatBubbleMessage(text: entry.text, isUser: entry.isUser),
          );
        }
      }
    } catch (_) {
      // โหลดประวัติไม่ได้ ก็เริ่มแชทจากหน้าว่างได้ตามปกติ
    }
    if (!mounted) return;
    setState(() => _isLoadingHistory = false);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    final image = _image;
    if ((text.isEmpty && image == null) || _isSending || _isResetting) return;

    _inputController.clear();
    setState(() {
      _errorText = null;
      widget.history.add(
        ChatBubbleMessage(text: text, isUser: true, imageBytes: image?.bytes),
      );
      _image = null;
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await widget.repository.sendMessage(
        widget.accessToken,
        widget.recipeId,
        text,
        image: image,
      );
      widget.history.add(ChatBubbleMessage(text: reply, isUser: false));
    } catch (error) {
      // ส่งไม่สำเร็จ เอาคำถามและรูปคืนไปไว้ในช่องพิมพ์ ให้กดส่งใหม่ได้
      _messages.removeLast();
      _inputController.text = text;
      _image = image;
      _showError(error);
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // ย่อรูปก่อนส่ง ให้ส่งเร็วและไม่เกิน 5MB ที่ backend รับ
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _image = ChatImage(bytes: bytes, filename: file.name));
    } catch (error) {
      _showError('เปิดรูปไม่ได้: $error');
    }
  }

  Future<void> _reset() async {
    if (_isResetting || _isSending) return;
    setState(() => _isResetting = true);
    try {
      await widget.repository.reset(widget.accessToken);
      if (!mounted) return;
      setState(widget.history.clear);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() => _errorText = error.toString());
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
              child: _isLoadingHistory && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? _buildEmpty()
                  : _buildMessages(),
            ),
            if (_isSending) _buildTyping(),
            if (_errorText != null) _buildError(_errorText!),
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
            onPressed: _isSending || _isResetting || _messages.isEmpty
                ? null
                : _reset,
            icon: _isResetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
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

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
          IconButton(
            tooltip: 'ปิด',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _errorText = null),
            icon: Icon(Icons.close_rounded, color: Colors.red.shade700),
          ),
        ],
      ),
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

  Widget _buildImagePreview(ChatImage image) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                image.bytes,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: _isSending ? null : () => setState(() => _image = null),
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    final image = _image;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null) _buildImagePreview(image),
          _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'แนบรูป',
            onPressed: _isSending ? null : _pickImage,
            color: FoodDetailColors.purple,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
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
                hintText: _image == null
                    ? 'พิมพ์คำถาม...'
                    : 'ถามเกี่ยวกับรูปนี้ (ไม่พิมพ์ก็ได้)',
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
            onPressed: _isSending || _isResetting ? null : _send,
            color: FoodDetailColors.purple,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
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
    final imageBytes = message.imageBytes;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageBytes, width: 200, fit: BoxFit.cover),
              ),
            if (imageBytes != null && message.text.isNotEmpty)
              const SizedBox(height: 8),
            if (message.text.isNotEmpty)
              SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
