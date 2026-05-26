import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final response = await api.post('/auth/login', data: {
        'identifier': _identifierController.text,
        'password': _passwordController.text,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.data['token']);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout
            ? 'Sunucuya bağlanılamadı'
            : e.response?.data?['message'] ?? 'Invalid credentials';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppConstants.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Decorative accent line
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Indie',
                      style: AppConstants.headingStyle,
                    ),
                    TextSpan(
                      text: 'Swipe',
                      style: AppConstants.headingStyle.copyWith(
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Discover hidden gems, daily.', style: AppConstants.subheadingStyle),

              const SizedBox(height: 52),

              // Input fields
              TextField(
                controller: _identifierController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppConstants.inputDecoration('Email or Username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppConstants.inputDecoration('Password'),
              ),

              const SizedBox(height: 28),

              // Sign in button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: AppConstants.primaryButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),

              const SizedBox(height: 20),

              // Register link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppConstants.secondaryTextColor, fontSize: 14),
                        ),
                        const TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
