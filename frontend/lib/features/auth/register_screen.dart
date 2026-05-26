import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.post('/auth/register', data: {
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout
            ? 'Sunucuya bağlanılamadı'
            : e.response?.data?['message'] ?? 'Registration failed. Check your inputs.';
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
              Text('Create\nAccount', style: AppConstants.headingStyle),
              const SizedBox(height: 8),
              Text('Join the indie gaming community.', style: AppConstants.subheadingStyle),

              const SizedBox(height: 44),

              // Input fields
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppConstants.inputDecoration('Username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                keyboardType: TextInputType.emailAddress,
                decoration: AppConstants.inputDecoration('Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppConstants.inputDecoration('Password (min. 8 characters)'),
              ),

              const SizedBox(height: 28),

              // Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: AppConstants.primaryButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),

              const SizedBox(height: 20),

              // Login link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: AppConstants.secondaryTextColor, fontSize: 14),
                        ),
                        const TextSpan(
                          text: 'Sign In',
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
