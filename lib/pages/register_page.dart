import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final dbRef = FirebaseDatabase.instance
      .refFromURL("https://activeloaninfo-default-rtdb.firebaseio.com/registration");

  String searchQuery = "";
  String filterBy = "bike";

  String getSearchValue(Map row) {
    if (filterBy == "bike") {
      return (row["name"] ?? "").toString().toLowerCase();
    }
    return (row["colC"] ?? "").toString().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: "Search",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          setState(() => searchQuery = val.toLowerCase()),
                    ),
                  ),

                  const SizedBox(width: 10),

                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: filterBy,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "bike", child: Text("Bike")),
                        DropdownMenuItem(value: "name", child: Text("Name")),
                      ],
                      onChanged: (val) {
                        setState(() {
                          filterBy = val!;
                          searchQuery = "";
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// LIST
            Expanded(
              child: StreamBuilder(
                stream: dbRef.onValue,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final event = snap.data as DatabaseEvent;
                  final map = event.snapshot.value as Map?;

                  if (map == null) {
                    return const Center(child: Text("No rows"));
                  }

                  final rows = map.entries
                      .where((e) => (e.value as Map)["submitted"] != true)
                      .toList();

                  final filtered = rows.where((e) {
                    final row = e.value as Map;
                    return getSearchValue(row).contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final entry = filtered[i];
                      final key = entry.key;
                      final row = entry.value as Map;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(row["colC"] ?? ""),
                          subtitle: Text("Bike: ${row["name"]}"),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await dbRef.child(key).update({"submitted": true});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 19, 100, 186), // blue
                              foregroundColor: Colors.white, // text color
                              minimumSize: const Size(70, 36), // optional, keeps the button consistent
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text("Submit"),
                          ),
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
    );
  }
}