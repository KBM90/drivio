import 'package:drivio_app/common/constants/routes.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  String selectedRole = 'Driver'; // Default role

  final AuthService authService = AuthService(); // Instance of AuthService

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? token = await authService.register(
      nameController.text,
      emailController.text,
      selectedRole,
      passwordController.text,
      confirmPasswordController.text,
    );

    setState(() => isLoading = false);
    if (!mounted) return;
    if (token != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      ); // Navigate to home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed! Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 10),
                Text(
                  "Register",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Create your account",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 30),

                // Full Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Full Name"),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Full Name is required" : null,
                ),

                SizedBox(height: 15),

                // Email Field
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) =>
                          value!.contains('@') ? null : "Enter a valid email",
                ),

                SizedBox(height: 15),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items:
                      ["Driver", "Passenger"]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                  decoration: InputDecoration(labelText: "Role"),
                ),

                SizedBox(height: 15),

                // Password Field
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => isPasswordVisible = !isPasswordVisible,
                          ),
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  validator:
                      (value) =>
                          value!.length < 6
                              ? "Password must be at least 6 characters"
                              : null,
                ),

                SizedBox(height: 15),

                // Confirm Password Field
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Repeat Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () =>
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible,
                          ),
                    ),
                  ),
                  obscureText: !isConfirmPasswordVisible,
                  validator:
                      (value) =>
                          value != passwordController.text
                              ? "Passwords do not match"
                              : null,
                ),

                SizedBox(height: 25),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),

                SizedBox(height: 20),

                // Already have an account? Login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      "I have an account? Log in",
                      style: TextStyle(fontSize: 16, color: Colors.green),
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
}
