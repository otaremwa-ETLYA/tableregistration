import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'branch_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/services.dart';   //



class AttendedPage extends StatefulWidget {
  const AttendedPage({super.key});


  @override
  State<AttendedPage> createState() => _AttendedPageState();
}

class _AttendedPageState extends State<AttendedPage> {
  final dbRef = BranchConfig.dbRef;

  final ValueNotifier<bool> isClearing = ValueNotifier(false);
  bool _cancelClear = false;

  // Function to unsubmit a single row
  void unsubmit(String key) {
    dbRef.child(key).update({"submitted": false});
  }

  // Function to unsubmit all rows
  Future<void> unsubmitAll(Map data) async {
    for (var entry in data.entries) {
      if ((entry.value as Map)["submitted"] == true) {
        await dbRef.child(entry.key)
            .update({"submitted": false});
      }
    }
  }

    @override
      Widget build(BuildContext context) {return Scaffold(
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
    .toList(growable: false);

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
  color: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: ListTile(
      leading: const Icon(
        Icons.check_circle,
        color: Color.fromARGB(255, 19, 100, 186),
      ),

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
        onPressed: () => unsubmit(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(93, 91, 64, 64),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
          elevation: 0,
        ),
        child: const Text(
          "Unsubmit",
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
        ),
      ),
    );
  },
),
floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

floatingActionButton: StreamBuilder(
  stream: dbRef.onValue,
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox.shrink();

    final event = snap.data as DatabaseEvent;
    final map = event.snapshot.value as Map?;

    if (map == null) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: isClearing,
      builder: (context, loading, _) {
        return FloatingActionButton.extended(
          onPressed: () async {
            if (loading) {
              // 🛑 CANCEL ACTION
              _cancelClear = true;
              isClearing.value = false;
              return;
            }

            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Clear All"),
                content: const Text(
                  "Are you sure you want to mark all submitted rows as unsubmitted?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            _cancelClear = false;
            isClearing.value = true;

            try {
              for (var entry in map.entries) {
                if (_cancelClear) break;

                final row = entry.value as Map;

                if (row["submitted"] == true) {
                  await dbRef.child(entry.key)
                      .update({"submitted": false});
                }
              }

              if (context.mounted && !_cancelClear) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All records cleared successfully"),
                  ),
                );
              }
            } finally {
              isClearing.value = false;
            }
          },

          label: Text(
            loading ? "Clearing... (tap to cancel)" : "Clear all",
            style: const TextStyle(color: Colors.white),
          ),

          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete, color: Colors.white),

          backgroundColor: Colors.grey,
        );
      },
    );
  },
),
);
  }
}