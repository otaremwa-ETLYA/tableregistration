import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'pages/branch_config.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/attended_page.dart';
import 'pages/self_register_page.dart';
import 'pages/new_entries_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDOW8...your_api_key...",
      authDomain: "activeloaninfo.firebaseapp.com",
      databaseURL: "https://activeloaninfo-default-rtdb.firebaseio.com",
      projectId: "activeloaninfo",
      storageBucket: "activeloaninfo.firebasestorage.app",
      messagingSenderId: "689636555223",
      appId: "1:689636555223:web:ce9883375a92238b443392",
      measurementId: "G-H9XPKJHWT0",
    ),
  );

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 19, 100, 186),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(), // Start with login
    );
  }
}

class MainPage extends StatelessWidget {
  final String username;
  const MainPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // Dynamic Firebase reference based on logged-in branch
    final dbRef = BranchConfig.dbRef;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Stack(
          children: [
            // Full-screen background image
            SizedBox.expand(
              child: Image.asset("lib/assets/bgd_image.jpg", fit: BoxFit.cover),
            ),

            // Optional semi-transparent overlay to improve readability
            Container(color: Colors.black.withOpacity(0.2)),

            // Centered constrained content with card effect
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white.withOpacity(
                    0.85,
                  ), // semi-transparent card
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),

                        /// HEADER ROW WITH LOGO AND USER INFO
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                          color: Colors.white, // white background
                          // borderRadius: const BorderRadius.only(
                          //   topLeft: Radius.circular(12),
                          //   topRight: Radius.circular(12),
                          // ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "lib/assets/logo.png",
                                height: 20,
                                fit: BoxFit.fitHeight,
                              ),

                              /// Take all remaining space for username/profile at right
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "|",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    const CircleAvatar(
                                      radius: 18,
                                      child: Icon(Icons.person),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// NAVIGATION BAR WITH BADGE ON ATTENDED
                        StreamBuilder(
                          stream: dbRef.onValue,
                          builder: (context, snapshot) {
                            int submittedCount = 0;

                            if (snapshot.hasData && snapshot.data != null) {
                              final data =
                                  (snapshot.data!)
                                      .snapshot
                                      .value;
                              if (data is Map) {
                                submittedCount =
                                    data.values
                                        .where(
                                          (entry) => entry['submitted'] == true,
                                        )
                                        .length;
                              }
                            }

                            return TabBar(
                              labelColor: const Color.fromARGB(
                                255,
                                19,
                                100,
                                186,
                              ),
                              unselectedLabelColor: Colors.black54,
                              indicatorColor: const Color.fromARGB(
                                255,
                                19,
                                100,
                                186,
                              ),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              tabs: [
                                const Tab(text: "Register"),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Attended"),
                                      const SizedBox(width: 6),
                                      if (submittedCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$submittedCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Tab(text: "Self Register"),
                                const Tab(text: "New Entries"),
                              ],
                            );
                          },
                        ),

                        const Expanded(
                          child: TabBarView(
                            children: [
                              RegisterPage(),
                              AttendedPage(),
                              SelfRegisterPage(),
                              NewEntriesPage(),
                            ],
                          ),
                        ),
                      ],
                    ),
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
