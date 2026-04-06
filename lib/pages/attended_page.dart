import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'branch_config.dart';



class AttendedPage extends StatelessWidget {
  const AttendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = BranchConfig.dbRef;

    // Function to unsubmit a single row
    void unsubmit(String key) {
      dbRef.child(key).update({"submitted": false});
    }

    // Function to unsubmit all rows
    Future<void> unsubmitAll(Map data) async {
      for (var entry in data.entries) {
        if ((entry.value as Map)["submitted"] == true) {
          await dbRef.child(entry.key).update({"submitted": false});
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: StreamBuilder(
  stream: dbRef.onValue,
  builder: (context, snap) {
    if (!snap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final event = snap.data as DatabaseEvent;
    final map = event.snapshot.value as Map?;

    if (map == null) {
      return const Center(child: Text("No attended members"));
    }

    final rows = map.entries
        .where((e) => (e.value as Map)["submitted"] == true)
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final key = rows[i].key;
            final row = rows[i].value as Map;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 2,
              color: Colors.transparent, // make card itself transparent
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // only the content is white
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Color.fromARGB(255, 19, 100, 186),
                  ),
                  title: Text(row["colC"] ?? ""),
                  subtitle: Text("Number: ${row["name"]}"),
                  trailing: InkWell(
  borderRadius: BorderRadius.circular(6),
  onTap: () => unsubmit(key),
  child: Image.asset(
    "lib/assets/UNSUBMIT.png",
    height: 40, // adjust as needed
    fit: BoxFit.contain,
  ),
),
                ),
              ),
            );
          },
        ),
      ),
    );
  },
),
floatingActionButton: StreamBuilder(
  stream: dbRef.onValue,
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox.shrink();
    final event = snap.data as DatabaseEvent;
    final map = event.snapshot.value as Map?;
    if (map == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () async {
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Clear All"),
            content: const Text(
                "Are you sure you want to mark all submitted rows as unsubmitted?"),
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
                child: const Text("Yes, Clear All"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await unsubmitAll(map);
        }
      },
      label: const Text(
        "Clear all",
        style: TextStyle(color: Colors.white),
      ),
      icon: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
      backgroundColor: Colors.grey,
    );
  },
),
);
  }
}