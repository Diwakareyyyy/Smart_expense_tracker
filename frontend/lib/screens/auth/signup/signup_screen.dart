import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/app_dialogs.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirm = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (password != confirm) {
      _showError("Passwords do not match");
      return;
    }

    final pwdErr = AuthService.validatePassword(password);
    if (pwdErr != null) {
      _showError(pwdErr);
      return;
    }

    setState(() => isLoading = true);

    final error = await AuthService.instance.signUpWithEmail(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    showMessageDialog(
      context,
      title: 'Success',
      message: 'Account created successfully!',
      onOk: () {
        if (mounted) context.go('/dashboard');
      },
    );
  }

  void _showError(String message) {
    showMessageDialog(context, title: 'Error', message: message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF5F7FA);
    final cardColor = isDark ? const Color(0xff111827) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create Account",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign up to start tracking expenses",
                        style: TextStyle(color: hintColor, fontSize: 16),
                      ),
                      const SizedBox(height: 35),
                      _field(nameController, "Enter your full name", Icons.person_outline, cardColor, textColor, hintColor),
                      const SizedBox(height: 18),
                      _field(emailController, "Enter your email", Icons.email_outlined, cardColor, textColor, hintColor,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 18),
                      _passwordField(
                        passwordController,
                        "Enter your password",
                        hidePassword,
                        cardColor,
                        textColor,
                        hintColor,
                        () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Must be 8+ chars with 1 uppercase, 1 digit & 1 special char (!@#\$)",
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 11),
                      ),
                      const SizedBox(height: 18),
                      _passwordField(confirmPasswordController, "Confirm your password", hideConfirm, cardColor, textColor, hintColor, () {
                        setState(() => hideConfirm = !hideConfirm);
                      }),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?", style: TextStyle(color: hintColor)),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text("Login", style: TextStyle(color: Color(0xff8B5CF6), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon,
      Color fillColor, Color textColor, Color hintColor,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String hint, bool hidden,
      Color fillColor, Color textColor, Color hintColor, VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 12),
        prefixIcon: Icon(Icons.lock_outline, color: hintColor),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility, color: hintColor),
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
