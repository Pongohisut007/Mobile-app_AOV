import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_application_1/widgets/login/login_footer.dart';
import 'package:flutter_application_1/widgets/login/login_form_fields.dart';
import 'package:flutter_application_1/widgets/login/login_social_buttons.dart';
import 'package:flutter_application_1/widgets/login/login_submit_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    this.onSignUp,
    this.errorMessage,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback? onSignUp;

  /// error จาก server (เช่น รหัสผ่านผิด) แสดงเหนือปุ่ม จนกว่าจะแก้ข้อมูล
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Form(
        key: formKey,
        // password manager เสนอเติม/บันทึกอีเมลกับรหัสผ่านคู่กัน
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoginFormFields(
                emailController: emailController,
                passwordController: passwordController,
                obscurePassword: obscurePassword,
                onTogglePassword: onTogglePassword,
                onSubmitted: onSubmit,
              ),
              if (errorMessage case final message?) ...[
                const SizedBox(height: 14),
                AuthErrorBanner(message: message),
              ],
              const SizedBox(height: 22),
              LoginSubmitButton(onPressed: onSubmit),
              const SizedBox(height: 22),
              const LoginSocialButtons(),
              const SizedBox(height: 26),
              LoginFooter(onSignUp: onSignUp),
            ],
          ),
        ),
      ),
    );
  }
}
