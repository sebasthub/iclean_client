import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'widgets/premium_text_field.dart';
import 'widgets/premium_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();

  Future<void> _login() async {
    final error = await _authController.login();
    
    if (error == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _authController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ListenableBuilder(
              listenable: _authController,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.cleaning_services_rounded,
                      size: 80,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Bem-vindo\nde volta',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para continuar',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    PremiumTextField(
                      controller: _authController.loginEmailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _authController.loginPasswordController,
                      label: 'Senha',
                      obscureText: true,
                    ),
                    const SizedBox(height: 40),

                    PremiumButton(
                      text: 'Entrar',
                      isLoading: _authController.isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.black87),
                      child: const Text(
                        'Não tem uma conta? Cadastre-se',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}
