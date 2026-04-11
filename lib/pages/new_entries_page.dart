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

  Future<void> clearAllNewEntries() async {
    await newRef.remove();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All entries cleared")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ================= MAIN CONTENT =================
        SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // CARD
                  Card(
                    elevation: 4,
                    color: Colors.white,
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
                              FocusScope.of(context)
                                  .requestFocus(nameFocus);
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

                          // ================= SUBMIT BUTTON (RESTORED) =================
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 19, 100, 186),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              onPressed: submitNewEntry,
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

                  const SizedBox(height: 20),

                  // LIST
                  SizedBox(
                    height: 400,
                    child: StreamBuilder(
                      stream: newRef.onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData ||
                            (snapshot.data!).snapshot.value == null) {
                          return const Center(
                            child: Text("No new entries yet"),
                          );
                        }

                        final data = (snapshot.data!).snapshot.value
                            as Map<dynamic, dynamic>;

                        final entries = data.entries.toList();

                        return ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry =
                                entries[index].value as Map<dynamic, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Text("• ",
                                      style: TextStyle(fontSize: 20)),
                                  Text(
                                    "${entry['bike'] ?? ''} - ${entry['name'] ?? ''}",
                                  ),
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
        ),

        // ================= FLOATING CLEAR ALL BUTTON =================
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.black87,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text(
              "Clear all",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Clear All"),
                  content: const Text("Delete all new entries?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await clearAllNewEntries();
              }
            },
          ),
        ),
      ],
    );
  }
}