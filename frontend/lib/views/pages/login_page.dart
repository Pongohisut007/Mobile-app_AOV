import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/user_cache.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
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
import 'package:flutter_application_1/widgets/login/login_form.dart';
import 'package:flutter_application_1/widgets/login/login_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
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
        if (state is AuthFailure) {
          showAppSnackBar(context, state.message, type: AppSnackType.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD96868),
        body: SafeArea(
          bottom: false,
          // ฟอร์มสีขาวยืดเต็มพื้นที่ที่เหลือจนถึงล่างสุด ไม่ให้เห็นพื้นแดงด้านล่าง
          // ถ้าเนื้อหายาวกว่าจอ (จอเล็ก/คีย์บอร์ดขึ้น) ก็ยังเลื่อนได้
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: LoginLogo(heightFactor: 0.32, widthFactor: 0.38),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  onSubmit: _submit,
                  onSignUp: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.register);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
