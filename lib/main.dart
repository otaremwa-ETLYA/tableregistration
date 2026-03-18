import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDOW8N1YFF2s44L5FFQxAZP4Grt84LRa70",
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 19, 100, 186),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AttendancePage(),
    );
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {

  final dbRef = FirebaseDatabase.instance
      .refFromURL("https://activeloaninfo-default-rtdb.firebaseio.com/registration");

  int attendanceCount = 0;
  String searchQuery = "";
  String filterBy = "bike";

  String getSearchValue(Map row) {
    if (filterBy == "bike") {
      return (row["name"] ?? "").toString().toLowerCase(); // bike number
    }
    return (row["colC"] ?? "").toString().toLowerCase(); // name
  }

  void showSubmittedList(Map map) {

    final submittedRows = map.entries
        .where((e) => (e.value as Map)["submitted"] == true)
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Attended Members"),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: submittedRows.length,
            itemBuilder: (_, i) {

              final row = submittedRows[i].value as Map;
              final bike = row["name"] ?? "";
              final name = row["colC"] ?? "";

              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(name),
                subtitle: Text("Bike: $bike"),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [

          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: filterBy == "bike"
                    ? "Search Bike Number"
                    : "Search Name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.trim().toLowerCase()),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 130,
            child: DropdownButtonFormField<String>(
              value: filterBy,
              isDense: true,
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
    );
  }

  Widget buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFFEAF1F8),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text("Name",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text("Bike Number",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text("Submit",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget buildRow(MapEntry entry) {

    final key = entry.key;
    final row = entry.value as Map;

    final bike = row["name"] ?? "";
    final name = row["colC"] ?? "";
    final submitted = row["submitted"] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),

      child: Row(
        children: [

          Expanded(
            flex: 4,
            child: Text(name),
          ),

          Expanded(
            flex: 3,
            child: Text(bike),
          ),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 19, 100, 186),
                minimumSize: const Size(40, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                submitted ? "Done" : "Submit",
                style: TextStyle(
                  fontSize: 12,
                  color: submitted ? Colors.green : const Color.fromARGB(255, 255, 255, 255), // <- change text color here
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: submitted
                  ? null
                  : () async {
                      await dbRef.child(key).update({"submitted": true});
                      setState(() {});
                    },
            ),
          ),

        ],
      ),
    );
  }

  Widget buildList(Map map) {

    attendanceCount =
        map.values.where((r) => (r as Map)["submitted"] == true).length;

    final rows = map.entries
        .where((e) => (e.value as Map)["submitted"] != true)
        .toList();

    final filtered = rows.where((e) {
      final row = e.value as Map;
      return getSearchValue(row).contains(searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text("No rows match the search."),
      );
    }

    return Column(
      children: [
        buildHeaderRow(),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) => buildRow(filtered[i]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Attendance"),

        actions: [

          StreamBuilder(
            stream: dbRef.onValue,
            builder: (context, snap) {

              if (!snap.hasData) {
                return const SizedBox();
              }

              final event = snap.data as DatabaseEvent;
              final map = event.snapshot.value as Map?;

              if (map == null) {
                return const SizedBox();
              }

              attendanceCount =
                  map.values.where((r) => (r as Map)["submitted"] == true).length;

              return GestureDetector(
                onTap: () => showSubmittedList(map),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      "Attended: $attendanceCount",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => searchQuery = ""),
          ),
        ],
      ),

      body: Column(
        children: [

          buildSearchBar(),

          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snap) {

                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final event = snap.data as DatabaseEvent;
                final map = event.snapshot.value as Map?;

                if (map == null || map.isEmpty) {
                  return const Center(
                    child: Text("No attendance rows available."),
                  );
                }

                return buildList(map);
              },
            ),
          ),

        ],
      ),
    );
  }
}