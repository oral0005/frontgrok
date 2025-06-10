import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Handle login process
  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('please_fill_in_all_fields'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.login(_usernameController.text, _passwordController.text);
      final user = await _apiService.getUserProfile();
      if (!mounted) return;

      // Set locale based on user profile
      if (user.language != null) {
        await context.setLocale(Locale(user.language!));
      }

      // Navigate to HomeScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(currentUser: user)),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Display snackbar with message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Clean up controllers
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Image.asset(
                    'assets/images/full.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  // Username input field
                  CustomTextField(
                    label: 'username'.tr(),
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 20),
                  // Password input field with toggle visibility
                  CustomTextField(
                    label: 'password'.tr(),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login button with translated text
                  CustomButton(
                    text: 'login'.tr(),
                    onPressed: _isLoading ? null : _login,
                    color: const Color(0xFF201731),
                  ),
                  const SizedBox(height: 10),
                  // Navigate to signup screen
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: Text(
                      'sign_up'.tr(),
                      style: const TextStyle(color: Colors.grey),
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