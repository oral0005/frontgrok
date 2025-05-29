import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Сначала регистрируем пользователя
        await _apiService.register(
          _usernameController.text,
          _passwordController.text,
          _phoneController.text,
          _nameController.text,
          _surnameController.text,
        );

        // После регистрации сразу логинимся
        await _apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          try {
            // После успешной регистрации отправляем код верификации
            await _apiService.sendVerificationCode(_phoneController.text);
            
            // Показываем экран верификации
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  phoneNumber: _phoneController.text,
                  onVerificationSuccess: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                ),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registration successful, but failed to send verification code: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
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
              child: Form(
                key: _formKey,
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
                      label: 'username'.tr(),
                      controller: _usernameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'phone'.tr(),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'password'.tr(),
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'name'.tr(),
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'surname'.tr(),
                      controller: _surnameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter surname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'sign_up'.tr(),
                      onPressed: _isLoading ? null : _register,
                      color: const Color(0xFF201731),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                      child: Text(
                        'already_have_account_login'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}