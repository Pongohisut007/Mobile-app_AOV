import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/language_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// หน้าตาที่หน้า login กับ register ใช้ร่วมกัน
/// โทนแดง→ส้มเดียวกับปุ่มหมวดที่เลือกอยู่ในหน้าหลัก (สีแรกที่เห็นหลังเข้าสู่ระบบ)
abstract final class AuthStyle {
  static const primary = Color(0xFFD32F2F);
  static const accent = Color(0xFFF57C00);
  static const label = Color(0xFF303030);
  static const muted = Color(0xFF8A8A8A);

  static const gradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const linkStyle = TextStyle(
    color: primary,
    fontWeight: FontWeight.w700,
  );

  /// ช่องกรอกมุมมน ขอบเทา โฟกัสแล้วขอบสีหลัก
  static InputDecoration input(String hint, {String? helper}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 14),
      helperText: helper,
      helperStyle: const TextStyle(color: muted, fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      enabledBorder: _border(const Color(0xFFE3E3E3)),
      focusedBorder: _border(primary, width: 1.5),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.5),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// รูปแบบอีเมลคร่าว ๆ ให้ตรงกับที่ backend ตรวจ (มีชื่อ @ โดเมน และจุด)
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isEmail(String value) => _emailPattern.hasMatch(value.trim());

  /// ความยาวรหัสผ่านที่ backend รับ (bcrypt ใช้ได้ไม่เกิน 72 byte)
  static const minPasswordLength = 8;
  static const maxPasswordLength = 72;
}

/// พื้นหลังไล่สีของหน้า login/register
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AuthStyle.gradient),
      child: child,
    );
  }
}

/// แถบ error ในฟอร์ม (อยู่จนกว่าผู้ใช้จะแก้ข้อมูล ไม่หายเองแบบ snackbar)
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC62828),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ปุ่มหลัก (เข้าสู่ระบบ / สมัครสมาชิก): ไล่สีแดง→ส้ม มีเงาส้ม
/// กำลังส่งข้อมูล (AuthLoading) = ตัวหมุนและกดซ้ำไม่ได้
/// หน้าที่ไม่ได้ใช้ AuthBloc (เช่น ลืมรหัสผ่าน) ส่ง [isLoading] มาเอง
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading case final loading?) return _build(loading);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _build(state is AuthLoading),
    );
  }

  Widget _build(bool isLoading) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isLoading ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AuthStyle.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AuthStyle.accent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มเปลี่ยนภาษามุมขวาบนของหน้า login/register
/// คนที่อ่านภาษาปัจจุบันไม่ออกก็เปลี่ยนได้ตั้งแต่ก่อนเข้าสู่ระบบ
class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => showLanguagePicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                AppLanguage.nativeName(Localizations.localeOf(context)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "หรือ" + ปุ่มเข้าสู่ระบบด้วย Google (ใช้ทั้งหน้า login และ register)
/// บัญชีใหม่จะถูกสร้างให้อัตโนมัติ อีเมลตรงกับบัญชีเดิมจะเข้าบัญชีเดิม
class AuthGoogleSection extends StatelessWidget {
  const AuthGoogleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.orDivider,
                style: const TextStyle(color: AuthStyle.muted),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => context.read<AuthBloc>().add(
                        const AuthGoogleRequested(),
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthStyle.label,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // โลโก้ตัว G สี่สีแบบง่าย (ไม่ต้องเพิ่มไฟล์รูป)
                    ShaderMask(
                      shaderCallback: (bounds) => const SweepGradient(
                        colors: [
                          Color(0xFFEA4335),
                          Color(0xFFFBBC05),
                          Color(0xFF34A853),
                          Color(0xFF4285F4),
                          Color(0xFFEA4335),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.continueWithGoogle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
