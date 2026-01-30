import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/debug_helper.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      
      if (result != null) {
        // Login/Registration successful
        if (!mounted) return;
        
        final isNewUser = result['is_new_user'] == true;
        final message = isNewUser ? "Registration Successful! Welcome!" : "Login Successful!";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.greenAccent,
          ),
        );
        
        // Navigate to Dashboard
        Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        // Cancelled or failed silently (e.g. user closed window)
      }
    } catch (e) {
      if (!mounted) return;
      
      if (e.toString().contains("ApiException: 10") || e.toString().contains("sign_in_failed")) {
         DebugHelper.showConfigurationError(context, e.toString());
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Failed: $e"),
              backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.cyanAccent)
            : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sign in to access premium features",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.network(
                        'http://pngimg.com/uploads/google/google_PNG19635.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.black),
                      ), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      label: const Text(
                        "Sign in with Google",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  const Text(
                     "OR",
                     style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  // Placeholder for Email/Password (Disabled for now as per flow focus)
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.02)
                     ),
                     child: const Column(
                        children: [
                           Text(
                             "Email login coming soon", 
                             style: TextStyle(color: Colors.white38)
                           )
                        ],
                     ),
                   )
                ],
              ),
            ),
        ),
      ),
    );
  }
}
