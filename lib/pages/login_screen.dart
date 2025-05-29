import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.login(_usernameController.text, _passwordController.text);
      final user = await _apiService.getUserProfile();
      if (mounted) {
        if (user.language != null) {
          await context.setLocale(Locale(user.language!));
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7FF), // Background color #fef7ff
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/full.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Username',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Password',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Login',
                    onPressed: _isLoading ? null : _login,
                    color: Color(0xFF201731),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.grey),
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