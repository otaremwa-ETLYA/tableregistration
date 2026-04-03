import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../pages/branch_config.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true; // Add this at the top of _LoginPageState
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  String error = "";
  bool loading = false;

  Future<void> login() async {
    setState(() {
  loading = true;
  error = "";
});

String enteredBranch = usernameController.text.trim().toLowerCase();
String enteredPassword = passwordController.text.trim();

if (enteredBranch.isEmpty || enteredPassword.isEmpty) {
  setState(() {
    error = "Please enter both username and password";
    loading = false;
  });
  return;
}

try {
  final ref = FirebaseDatabase.instance.ref("registration/user");
  final snapshot = await ref.get();

  if (!snapshot.exists) {
    setState(() {
      error = "No branches found";
      loading = false;
    });
    return;
  }

  final users = Map<String, dynamic>.from(snapshot.value as Map);
  bool found = false;

  for (var entry in users.entries) {
    String branchKey = entry.key.toLowerCase(); // lowercase for comparison
    final branchData = Map<String, dynamic>.from(entry.value as Map);
    final storedPassword = branchData["password"]?.toString() ?? "";

    if (branchKey == enteredBranch && storedPassword == enteredPassword) {
      BranchConfig.branch = entry.key; // preserve original case
      found = true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
      break;
    }
  }

  if (!found) {
    setState(() {
      error = "Incorrect branch or password";
      loading = false;
    });
  }
} catch (e) {
  setState(() {
    error = "Error: ${e.toString()}";
    loading = false;
  });
}}

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("lib/assets/logo.png", height: 80),
              const SizedBox(height: 25),
              const Text(
                "Branch Login",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Username input
              TextField(
                controller: usernameController,
                focusNode: usernameFocus,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Username",
                  hintStyle: const TextStyle(fontSize: 14),
                ),
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              const SizedBox(height: 15),

              // Password input
              TextField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Password",
                  hintStyle: const TextStyle(fontSize: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) {
                  login();
                },
              ),
              const SizedBox(height: 20),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In"),
                ),
              ),

              const SizedBox(height: 10),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}