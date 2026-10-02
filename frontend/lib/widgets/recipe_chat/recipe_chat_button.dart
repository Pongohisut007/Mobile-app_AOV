import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/chat_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/recipe_chat/recipe_chat_sheet.dart';

/// ปุ่ม "ถาม AI" แสดงเฉพาะคนที่ login และมีสิทธิ์ใช้สูตรนี้
class RecipeChatButton extends StatefulWidget {
  const RecipeChatButton({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeChatButton> createState() => _RecipeChatButtonState();
}

class _RecipeChatButtonState extends State<RecipeChatButton> {
  final _repository = ChatRepository(baseUrl: ApiConfig.apiBaseUrl);
  final _tokenStorage = TokenStorage();

  String? _accessToken;
  bool _canChat = false;

  // เก็บแชทไว้ที่นี่ ปิด popup แล้วเปิดใหม่ก็ยังเห็นแชทเดิม
  final _history = RecipeChatHistory();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return;

    try {
      final canChat = await _repository.canChat(token, widget.recipeId);
      if (!mounted) return;
      setState(() {
        _accessToken = token;
        _canChat = canChat;
      });
    } catch (_) {
      // เช็กสิทธิ์ไม่ได้ ก็แค่ไม่แสดงปุ่ม
    }
  }

  void _openChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecipeChatSheet(
        repository: _repository,
        accessToken: _accessToken!,
        recipeId: widget.recipeId,
        history: _history,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canChat) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _openChat,
        style: OutlinedButton.styleFrom(
          foregroundColor: FoodDetailColors.purple,
          side: const BorderSide(color: FoodDetailColors.purple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          'ถาม AI เกี่ยวกับสูตรนี้',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
