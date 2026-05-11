import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood_app/screens/detection_screen.dart';
import 'package:mood_app/screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_app/services/mood_history_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;
  String? emailError;
  String? passwordError;

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (email.isEmpty && password.isEmpty) {
      setState(() {
        emailError = "Please enter email and password";
        passwordError = "Please enter email and password";
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        emailError = "Please enter your email";
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = "Please enter your password";
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String realName = userDoc.get('full_name');

        // Removed email verification check for easier testing


        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', realName);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_id', userCredential.user!.uid);

        // migrate guest history (if any) to this signed-in user
        await MoodHistoryService().transferAnonToCurrentUser();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionScreen(userName: realName),
          ),
        );
      } else {
        _showSnackBar(
          "Profile data synchronization error. Please contact support.",
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email address.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-credential':
          errorMessage = "Invalid email or password. Please check and try again.";
          break;
        case 'invalid-email':
          errorMessage = "The email address format is not valid.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled by the administrator.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Please try again later.";
          break;
        default:
          errorMessage = "Authentication failed: ${e.message}";
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to receive a reset link.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link has been sent to your email.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        msg = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email format.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFBECEB), Color(0xFFEDB1AA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      color: Color(0xFFC04F4C),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    emailController,
                    "Email Address",
                    Icons.email_outlined,
                    errorText: emailError,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    passwordController,
                    "Password",
                    Icons.lock_outline,
                    isPasswordField: true,
                    errorText: passwordError,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _sendPasswordReset(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFFC04F4C),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFC04F4C),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC04F4C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "New here? ",
                        style: TextStyle(color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        ),
                        child: const Text(
                          "Create an account",
                          style: TextStyle(
                            color: Color(0xFFC04F4C),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _handleGuest,
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black54,
                      ),
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

  void _handleGuest() async {
    // Persist a lightweight guest session locally (not Firebase). History will be stored under the anon key.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', 'Guest');
    await prefs.setBool('isGuest', true);
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionScreen(userName: 'Guest'),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPasswordField = false,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPasswordField ? _isObscured : false,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: const Color(0xFFC04F4C)),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFC04F4C),
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : null,
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorText != null ? Colors.redAccent : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorText != null ? Colors.redAccent : const Color(0xFFC04F4C),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
