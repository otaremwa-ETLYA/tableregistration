import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pages/branch_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/services.dart';   // for Clipboard

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
final dbRef = BranchConfig.dbRef;

  String searchQuery = "";
  String filterBy = "name";

String getSearchValue(Map row) {
  if (filterBy == "name") {
    return (row["colC"] ?? "").toString().toLowerCase();
  }
  return (row["name"] ?? "").toString().toLowerCase();
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
                        DropdownMenuItem(value: "bike", child: Text("Number")),
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
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: ListTile(
      title: Text(
        row["colC"] ?? "",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),

      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "${row["name"] ?? ""} | ",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
  onTap: () async {
    String phone = row["colD"]?.toString() ?? "";
    phone = phone.trim();

    if (phone.isNotEmpty) {
      if (!phone.startsWith("0")) {
        phone = "0$phone";
      }

      if (kIsWeb) {
        // 👉 WEB: copy instead of call
        await Clipboard.setData(ClipboardData(text: phone));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Copied $phone")),
        );
      } else {
        // 👉 MOBILE: call
        final uri = Uri(scheme: 'tel', path: phone);
        await launchUrl(uri);
      }
    }
  },
  onLongPress: () async {
    // 👉 ALWAYS allow manual copy (both web & mobile)
    String phone = row["colD"]?.toString() ?? "";
    phone = phone.trim();

    if (phone.isNotEmpty) {
      if (!phone.startsWith("0")) {
        phone = "0$phone";
      }

      await Clipboard.setData(ClipboardData(text: phone));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copied $phone")),
      );
    }
  },
  child: Text(
    row["colD"] ?? "",
    style: const TextStyle(
      color: Colors.grey,
      fontSize: 12,
      decoration: TextDecoration.underline,
    ),
  ),
),
              ),
            ],
          ),
        ),
      ),

      trailing: ElevatedButton(
        onPressed: () async {
          await dbRef.child(key).update({"submitted": true});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 19, 100, 186),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
          elevation: 0,
        ),
        child: const Text(
          "Submit",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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