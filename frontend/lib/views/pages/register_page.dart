import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/user_cache.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_application_1/widgets/common/auth_style.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/register/register_form.dart';
import 'package:flutter_application_1/widgets/register/register_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // ให้ password manager บันทึกบัญชีที่เพิ่งสมัครได้
          TextInput.finishAutofillContext();
          clearUserCaches();
          // secure storage ไม่มี stream บอกว่า token เปลี่ยน
          // ต้องสั่งให้ตะกร้ากับหัวใจโหลดของคนนี้เองหลัง AuthBloc เขียน token แล้ว
          context.read<CartBloc>().add(const CartRequested());
          context.read<FavoriteBloc>().add(const FavoritesRequested());
          context.read<PurchasedRecipesBloc>().add(
            const PurchasedRecipesRequested(),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
        // AuthFailure แสดงเป็นแถบ error ในฟอร์ม (RegisterForm ฟังเอง)
      },
      // ย้อนกลับ (ทั้งปุ่มบนจอและปุ่ม back ของระบบ) ให้กลับไปหน้า login
      // ใช้ replace แทน push จะได้ไม่มีหน้า login/register ซ้อนกันใน stack
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
        child: Scaffold(
          backgroundColor: AuthStyle.primary,
          body: AuthBackground(
            child: SafeArea(
              bottom: false,
              // โลโก้ย่อตามการเลื่อน ส่วนฟอร์มสีขาวยืดถึงล่างสุดเสมอ
              child: CustomScrollView(
                slivers: [
                  const RegisterLogoHeader(),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: RegisterForm(
                      onSubmit:
                          ({
                            required email,
                            required password,
                            required displayName,
                          }) {
                            context.read<AuthBloc>().add(
                              AuthRegisterRequested(
                                email: email,
                                password: password,
                                displayName: displayName,
                              ),
                            );
                          },
                      onSignIn: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
