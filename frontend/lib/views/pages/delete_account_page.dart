import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/data/session.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// ลบบัญชี: อธิบายผลที่จะเกิด + ยืนยันรหัสผ่าน + ติ๊กยอมรับ
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  static const _danger = Color(0xFFD54444);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _repository = HttpAuthRepository(baseUrl: ApiConfig.apiBaseUrl);

  bool _confirmed = false;
  bool _showPassword = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_isDeleting || !_confirmed) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isDeleting = true);
    try {
      final token = await TokenStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw const AuthRepositoryException(
          'Your session has expired. Please sign in again.',
        );
      }
      await _repository.deleteAccount(
        accessToken: token,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await signOutLocally(context);
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: ProfileColors.background,
        appBar: RecipeFormStyle.appBar(title: 'ลบบัญชี'),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _isDeleting || !_confirmed ? null : _delete,
            style: RecipeFormStyle.primaryButton().copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? _danger.withValues(alpha: 0.35)
                    : _danger,
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            icon: _isDeleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded),
            label: Text(_isDeleting ? 'กำลังลบบัญชี...' : 'ลบบัญชีถาวร'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: _danger),
                        SizedBox(width: 8),
                        Text(
                          'ลบแล้วกู้คืนไม่ได้',
                          style: TextStyle(
                            color: _danger,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _Bullet(
                      'ออกจากระบบทุกอุปกรณ์ และเข้าสู่ระบบด้วยบัญชีนี้ไม่ได้อีก',
                    ),
                    _Bullet(
                      'ชื่อ รูปโปรไฟล์ และอีเมลถูกลบ '
                      'กลับมาสมัครใหม่ด้วยอีเมลเดิมได้ แต่จะเป็นบัญชีใหม่',
                    ),
                    _Bullet(
                      'สูตรที่คุณสร้างจะไม่แสดงให้ใครเห็นอีก '
                      'ยกเว้นคนที่ซื้อไปแล้วยังเปิดดูได้',
                    ),
                    _Bullet('รายการโปรด ตะกร้า และสูตรที่คุณซื้อไว้จะหายไป'),
                    _Bullet(
                      'คอมเมนต์และรีวิวยังอยู่ แต่จะแสดงเป็น '
                      '"ผู้ใช้ที่ลบบัญชีแล้ว"',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RecipeFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isDeleting,
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration:
                          RecipeFormStyle.input(
                            label: 'ยืนยันด้วยรหัสผ่าน',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: RecipeFormStyle.muted,
                            ),
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              tooltip: _showPassword
                                  ? 'ซ่อนรหัสผ่าน'
                                  : 'แสดงรหัสผ่าน',
                              color: RecipeFormStyle.muted,
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'กรอกรหัสผ่าน'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _confirmed,
                      onChanged: _isDeleting
                          ? null
                          : (value) =>
                                setState(() => _confirmed = value ?? false),
                      activeColor: _danger,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'ฉันเข้าใจว่าการลบบัญชีกู้คืนไม่ได้',
                        style: TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: ProfileColors.ink, height: 1.45),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ProfileColors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
