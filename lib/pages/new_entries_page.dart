import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'branch_config.dart';

class NewEntriesPage extends StatefulWidget {
  const NewEntriesPage({super.key});

  @override
  State<NewEntriesPage> createState() => _NewEntriesPageState();
}

class _NewEntriesPageState extends State<NewEntriesPage> {
  final bikeController = TextEditingController();
  final nameController = TextEditingController();

final newRef = FirebaseDatabase.instance
    .ref("registration/newEntries/${BranchConfig.branch}");

final bikeFocus = FocusNode();
final nameFocus = FocusNode();

Future<void> submitNewEntry() async {
  final bike = bikeController.text.trim();
  final name = nameController.text.trim();

  if (bike.isEmpty && name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter at least one field")),
    );
    return;
  }

  await newRef.push().set({
    "bike": bike,
    "name": name,
  });

  bikeController.clear();
  nameController.clear();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("New entry added")),
  );

  FocusScope.of(context).requestFocus(bikeFocus);
}


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Space from TabBar
              const SizedBox(height: 20),

              // Card for adding new entries
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add New Entry",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 19, 100, 186),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: bikeController,
                        focusNode: bikeFocus,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Bike Number",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(nameFocus);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        focusNode: nameFocus,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          submitNewEntry();
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 19, 100, 186),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            submitNewEntry();
                          },
                          child: const Text(
                            "Submit",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20), // space between card and list

              // Bullet-style list of new entries
              SizedBox(
                height: 400, // or any preferred height
                child: StreamBuilder(
                  stream: newRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        (snapshot.data!).snapshot.value == null) {
                      return const Center(child: Text("No new entries yet"));
                    }

                    final data = (snapshot.data!).snapshot.value as Map<dynamic, dynamic>;
                    final entries = data.entries.toList();

                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index].value as Map<dynamic, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Text("• ", style: TextStyle(fontSize: 20)), // bullet
                              Text("${entry['bike'] ?? ''} - ${entry['name'] ?? ''}"),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}