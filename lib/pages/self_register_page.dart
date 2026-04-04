import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'branch_config.dart';

class SelfRegisterPage extends StatefulWidget {
  const SelfRegisterPage({super.key});

  @override
  State<SelfRegisterPage> createState() => _SelfRegisterPageState();
}

class _SelfRegisterPageState extends State<SelfRegisterPage> {

  final dbRef = BranchConfig.dbRef;


  final bikeController = TextEditingController();
  final nameController = TextEditingController();

  final bikeFocus = FocusNode();
  final nameFocus = FocusNode();

  bool updating = false;

  void autofillFromBike(String bike, List<Map> members) {
    if (updating) return;
    updating = true;

    final row = members.firstWhere(
      (r) => (r["name"] ?? "").toString().toLowerCase() == bike.toLowerCase(),
      orElse: () => {},
    );

    if (row.isNotEmpty) {
      nameController.text = (row["colC"] ?? "").toString();
    }

    updating = false;
  }

  void autofillFromName(String name, List<Map> members) {
    if (updating) return;
    updating = true;

    final row = members.firstWhere(
      (r) => (r["colC"] ?? "").toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );

    if (row.isNotEmpty) {
      bikeController.text = (row["name"] ?? "").toString();
    }

    updating = false;
  }

@override
Widget build(BuildContext context) {
  return StreamBuilder(
    stream: dbRef.onValue,
    builder: (context, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final event = snap.data as DatabaseEvent;
      final map = event.snapshot.value as Map?;

      if (map == null) {
        return const Center(child: Text("No members found"));
      }

      final members = map.values.map((e) => e as Map).toList();

      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Space above the card (same as before)
                const SizedBox(height: 20),

                // The card
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
                          "Self Registration",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 19, 100, 186),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Bike Number Autocomplete
                        RawAutocomplete<String>(
                          textEditingController: bikeController,
                          focusNode: bikeFocus,
                          optionsBuilder: (text) {
                            if (text.text.isEmpty) return const Iterable<String>.empty();
                            return members
                                .map((e) => (e["name"] ?? "").toString())
                                .where((bike) => bike.toLowerCase().contains(text.text.toLowerCase()));
                          },
                          onSelected: (bike) => autofillFromBike(bike, members),
                          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Bike Number",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => autofillFromBike(val, members),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: SizedBox(
                                  height: 200,
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: options.map((option) {
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Name Autocomplete
                        RawAutocomplete<String>(
                          textEditingController: nameController,
                          focusNode: nameFocus,
                          optionsBuilder: (text) {
                            if (text.text.isEmpty) return const Iterable<String>.empty();
                            return members
                                .map((e) => (e["colC"] ?? "").toString())
                                .where((name) => name.toLowerCase().contains(text.text.toLowerCase()));
                          },
                          onSelected: (name) => autofillFromName(name, members),
                          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => autofillFromName(val, members),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: SizedBox(
                                  height: 200,
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: options.map((option) {
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Submit button
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
                            onPressed: () async {
                              final matchEntry = map.entries.firstWhere(
                                (e) => (e.value as Map)["name"] == bikeController.text,
                                orElse: () => MapEntry("", {}),
                              );

                              if (matchEntry.key != "") {
                                await dbRef.child(matchEntry.key).update({"submitted": true});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Submitted successfully")),
                                );

                                bikeController.clear();
                                nameController.clear();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No matching member found")),
                                );
                              }
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

                // Space below the card
                const SizedBox(height: 20),

                // Your message
                const Text(
                  "Thanks for attending Table Fellowship. Blessings!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                // Space after the message
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}