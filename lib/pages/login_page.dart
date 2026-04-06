import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/branch_config.dart';
import '../main.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool _obscurePassword = true; // Add this at the top of _LoginPageState
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  String error = "";
  bool loading = false;

@override
void initState() {
  super.initState();
  loadSavedCredentials();
}

Future<void> loadSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();

  String? savedUser = prefs.getString("username");
  String? savedPass = prefs.getString("password");
  bool savedRemember = prefs.getBool("remember") ?? false;

  if (savedRemember) {
    usernameController.text = savedUser ?? "";
    passwordController.text = savedPass ?? "";
    rememberMe = true;
  }

  // Set focus AFTER loading credentials
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (usernameController.text.isNotEmpty) {
      FocusScope.of(context).requestFocus(passwordFocus);
    } else {
      FocusScope.of(context).requestFocus(usernameFocus);
    }
  });
}

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
      String branchKey = entry.key.toLowerCase();
      final branchData = Map<String, dynamic>.from(entry.value as Map);
      final storedPassword = branchData["password"]?.toString() ?? "";

      if (branchKey == enteredBranch && storedPassword == enteredPassword) {

        // Save credentials
        final prefs = await SharedPreferences.getInstance();

        if (rememberMe) {
          await prefs.setString("username", enteredBranch);
          await prefs.setString("password", enteredPassword);
          await prefs.setBool("remember", true);
        } else {
          await prefs.remove("username");
          await prefs.remove("password");
          await prefs.setBool("remember", false);
        }

        BranchConfig.branch = entry.key;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(
              username: enteredBranch,
            ),
          ),
        );

        found = true;
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
  }
}

@override
void dispose() {
  usernameController.dispose();
  passwordController.dispose();
  usernameFocus.dispose();
  passwordFocus.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {return Scaffold(
  body: Stack(
    children: [
      // Background image
      SizedBox.expand(
        child: Image.asset(
          "lib/assets/bgd_image.jpg",
          fit: BoxFit.cover,
        ),
      ),

      // Centered card content
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8, // shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white.withOpacity(0.70),// card background
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("lib/assets/logo.png", height: 80),
                  const SizedBox(height: 25),
                  const Text(
                    "Login to get started with Table Fellowship Engagement Registration.",
                    style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Username input
                  TextField(
                    controller: usernameController,
                    focusNode: usernameFocus,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 19, 100, 186),
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color.fromARGB(255, 19, 100, 186),
                      ),
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
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 19, 100, 186),
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color.fromARGB(255, 19, 100, 186),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value!;
                        });
                      },
                    ),
                    const Text(
                      "Save this password",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                  const SizedBox(height: 20),

                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 19, 100, 186),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(error, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);}
}