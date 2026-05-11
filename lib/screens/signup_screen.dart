import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood_app/screens/detection_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC04F4C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> handleSignUp() async {
    String userName = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (userName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("All fields are required to create an account.");
      return;
    }

    if (password.length < 8) {
      _showSnackBar("Password is too short. Minimum 8 characters required.");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match. Please verify and try again.");
      return;
    }

    // Remove Gmail-only restriction to allow all email providers
    
    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'full_name': userName,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': userCredential.user!.uid,
          });

      _showSnackBar('Account created successfully! Welcome.');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DetectionScreen(userName: userName),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered. Try logging in instead.";
          break;
        case 'invalid-email':
          errorMessage = "The email address provided is not valid.";
          break;
        case 'weak-password':
          errorMessage = "The password is too weak. Please use a stronger password.";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/Password accounts are not enabled. Contact support.";
          break;
        default:
          errorMessage = "Registration failed: ${e.message}";
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPasswordField = false,
    bool? isObscured,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPasswordField ? (isObscured ?? true) : false,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: const Color(0xFFC04F4C)),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  (isObscured ?? true)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: const Color(0xFFC04F4C),
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC04F4C), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Color(0xFFC04F4C),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join us to start tracking your mood",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  nameController,
                  "Full Name",
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  emailController,
                  "Email Address",
                  Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  passwordController,
                  "Password",
                  Icons.lock_outline,
                  isPasswordField: true,
                  isObscured: _isObscured,
                  onToggle: () => setState(() => _isObscured = !_isObscured),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  confirmPasswordController,
                  "Confirm Password",
                  Icons.lock_reset_outlined,
                  isPasswordField: true,
                  isObscured: _isConfirmObscured,
                  onToggle: () =>
                      setState(() => _isConfirmObscured = !_isConfirmObscured),
                ),
                const SizedBox(height: 32),
                isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFC04F4C))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleSignUp,
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
                            "SIGN UP",
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
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login here",
                        style: TextStyle(
                          color: Color(0xFFC04F4C),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
