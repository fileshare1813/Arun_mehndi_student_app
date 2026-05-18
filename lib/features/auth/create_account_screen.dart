import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/main_layout.dart';

import 'auth_provider.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  /*
  |--------------------------------------------------------------------------
  | FORM KEY
  |--------------------------------------------------------------------------
  */

  final _formKey = GlobalKey<FormState>();

  /*
  |--------------------------------------------------------------------------
  | CONTROLLERS
  |--------------------------------------------------------------------------
  */

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final phoneController = TextEditingController();

  final passwordController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | LOADING
  |--------------------------------------------------------------------------
  */

  bool loading = false;

  /*
  |--------------------------------------------------------------------------
  | REGISTER FUNCTION
  |--------------------------------------------------------------------------
  */

  Future<void> register() async {
    /*
    |--------------------------------------------------------------------------
    | VALIDATION
    |--------------------------------------------------------------------------
    */

    if (nameController.text.trim().isEmpty) {
      showMessage("Enter full name");

      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage("Enter email");

      return;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage("Enter mobile number");

      return;
    }

    if (passwordController.text.trim().length < 6) {
      showMessage("Password must be at least 6 characters");

      return;
    }

    /*
    |--------------------------------------------------------------------------
    | LOADING START
    |--------------------------------------------------------------------------
    */

    setState(() {
      loading = true;
    });

    try {
      /*
      |--------------------------------------------------------------------------
      | AUTH PROVIDER
      |--------------------------------------------------------------------------
      */

      final authProvider = context.read<AuthProvider>();

      /*
      |--------------------------------------------------------------------------
      | REGISTER USER
      |--------------------------------------------------------------------------
      */

      bool success = await authProvider.registerUser(
        nameController.text.trim(),

        emailController.text.trim(),

        phoneController.text.trim(),

        passwordController.text.trim(),
      );

      /*
      |--------------------------------------------------------------------------
      | SUCCESS
      |--------------------------------------------------------------------------
      */

      if (success) {
        showMessage("Account created successfully");

        /*
        |--------------------------------------------------------------------------
        | REDIRECT TO HOME
        |--------------------------------------------------------------------------
        */

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,

          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),

          (route) => false,
        );
      } else {
        showMessage("Account creation failed");
      }
    } catch (e) {
      debugPrint("REGISTER ERROR => $e");

      showMessage("Something went wrong");
    }

    /*
    |--------------------------------------------------------------------------
    | LOADING STOP
    |--------------------------------------------------------------------------
    */

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | SHOW MESSAGE
  |--------------------------------------------------------------------------
  */

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();

    emailController.dispose();

    phoneController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 30),

                /*
                |--------------------------------------------------------------------------
                | LOGO
                |--------------------------------------------------------------------------
                */
                Center(
                  child: Image.asset(
                    "assets/images/splash_logo.jpeg",

                    height: 80,
                  ),
                ),

                const SizedBox(height: 30),

                /*
                |--------------------------------------------------------------------------
                | TITLE
                |--------------------------------------------------------------------------
                */
                Text("Create Account", style: AppTextStyles.heading),

                const SizedBox(height: 8),

                Text(
                  "Start learning Mehndi like a professional",

                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 40),

                /*
                |--------------------------------------------------------------------------
                | NAME
                |--------------------------------------------------------------------------
                */
                inputField("Full Name", Icons.person, nameController),

                const SizedBox(height: 16),

                /*
                |--------------------------------------------------------------------------
                | EMAIL
                |--------------------------------------------------------------------------
                */
                inputField("Email", Icons.email, emailController),

                const SizedBox(height: 16),

                /*
                |--------------------------------------------------------------------------
                | PHONE
                |--------------------------------------------------------------------------
                */
                inputField("Mobile Number", Icons.phone, phoneController),

                const SizedBox(height: 16),

                /*
                |--------------------------------------------------------------------------
                | PASSWORD
                |--------------------------------------------------------------------------
                */
                inputField(
                  "Password",

                  Icons.lock,

                  passwordController,

                  isPassword: true,
                ),

                const SizedBox(height: 30),

                /*
                |--------------------------------------------------------------------------
                | REGISTER BUTTON
                |--------------------------------------------------------------------------
                */
                GestureDetector(
                  onTap: loading ? null : register,

                  child: Container(
                    height: 52,

                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: AppColors.primary,

                      borderRadius: BorderRadius.circular(14),

                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.4),

                          blurRadius: 20,
                        ),
                      ],
                    ),

                    child: Center(
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Text(
                                  "Create Account",

                                  style: TextStyle(
                                    color: Colors.white,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(width: 8),

                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /*
                |--------------------------------------------------------------------------
                | LOGIN REDIRECT
                |--------------------------------------------------------------------------
                */
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },

                    child: const Text(
                      "Already have an account? Login",

                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | INPUT FIELD
  |--------------------------------------------------------------------------
  */

  Widget inputField(
    String hint,

    IconData icon,

    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,

      obscureText: isPassword,

      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),

        hintText: hint,

        hintStyle: const TextStyle(color: Colors.white38),

        filled: true,

        fillColor: const Color(0xFF1E1E1E),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
