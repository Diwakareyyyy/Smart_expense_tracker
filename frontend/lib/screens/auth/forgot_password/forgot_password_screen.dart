import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/app_dialogs.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showError("Please enter your registered email");
      return;
    }

    setState(() => isLoading = true);

    final (error, devOtp) =
        await AuthService.instance.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    showMessageDialog(
      context,
      title: 'Success',
      message: devOtp != null
          ? "Email is not configured yet. Your OTP is: $devOtp"
          : "OTP has been sent to your email. Please check your inbox.",
      onOk: () {
        if (mounted) setState(() => otpSent = true);
      },
    );
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (otp.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (otp.length != 6) {
      _showError("OTP must be exactly 6 digits");
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

    final error = await AuthService.instance.verifyAndResetPassword(
      email: email,
      otp: otp,
      newPassword: password,
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
      message: 'Password reset successful! Please login with your new password.',
      onOk: () {
        if (mounted) context.go('/login');
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
                      Icon(Icons.lock_reset, size: 60, color: const Color(0xff7C3AED)),
                      const SizedBox(height: 20),
                      Text(
                        otpSent ? "Reset Password" : "Forgot Password?",
                        style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        otpSent
                            ? "Enter the 6-digit OTP code sent to your email along with your new password."
                            : "Enter your registered email address. We'll send an OTP verification code to reset your password.",
                        style: TextStyle(color: hintColor, fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 35),

                      if (!otpSent) ...[
                        // Step 1: Request OTP
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Enter your registered email",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Send OTP", style: TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                      ] else ...[
                        // Step 2: Input OTP and new Password
                        TextField(
                          controller: emailController,
                          readOnly: true,
                          style: TextStyle(color: hintColor),
                          decoration: InputDecoration(
                            hintText: "Email",
                            prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                            filled: true,
                            fillColor: cardColor.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "6-Digit OTP",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.lock_clock_outlined, color: hintColor),
                            counterText: "",
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Enter new password",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePassword = !hidePassword),
                              icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility, color: hintColor),
                            ),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: hideConfirm,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Confirm new password",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hideConfirm = !hideConfirm),
                              icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility, color: hintColor),
                            ),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : sendOtp,
                            child: const Text(
                              "Resend OTP",
                              style: TextStyle(color: Color(0xff8B5CF6), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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
}
