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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AttendancePage(),
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
  String filterBy = "bike"; // bike or name


  String getSearchValue(Map row) {
    if (filterBy == "bike") {
      return (row["bike"] ?? "").toString().toLowerCase();
    }
    return (row["colC"] ?? "").toString().toLowerCase();
  }


  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [

          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                labelText: filterBy == "bike"
                    ? "Search by Bike Number"
                    : "Search by Name",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.trim().toLowerCase()),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: filterBy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "bike",
                  child: Text("Bike Number"),
                ),
                DropdownMenuItem(
                  value: "name",
                  child: Text("Name"),
                ),
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
        child: Text("No rows match the search.", style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => buildRow(filtered[i]),
    );
  }


  Widget buildRow(MapEntry entry) {

    final key = entry.key;
    final row = entry.value as Map;

    final bike = row["bike"] ?? "";
    final name = row["colC"] ?? "";
    final colD = row["colD"] ?? "";
    final submitted = row["submitted"] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: ListTile(
        title: Text("$bike - $name"),
        subtitle: Text("D: $colD"),

        trailing: ElevatedButton(
          child: Text(submitted ? "Submitted" : "Submit"),
          onPressed: submitted
              ? null
              : () async {
                  await dbRef.child(key).update({"submitted": true});
                  setState(() {});
                },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Attendance"),

        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "Attended: $attendanceCount",
                style: const TextStyle(fontSize: 18),
              ),
            ),
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
                  attendanceCount = 0;
                  return const Center(
                    child: Text(
                      "No attendance rows available.",
                      style: TextStyle(fontSize: 18),
                    ),
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

//#####################
//WITHOUT FILTER OPTION
//#####################

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//       apiKey: "AIzaSyDOW8N1YFF2s44L5FFQxAZP4Grt84LRa70",
//       authDomain: "activeloaninfo.firebaseapp.com",
//       databaseURL: "https://activeloaninfo-default-rtdb.firebaseio.com",
//       projectId: "activeloaninfo",
//       storageBucket: "activeloaninfo.firebasestorage.app",
//       messagingSenderId: "689636555223",
//       appId: "1:689636555223:web:ce9883375a92238b443392",
//       measurementId: "G-H9XPKJHWT0",
//     ),
//   );

//   runApp(const AttendanceApp());
// }

// class AttendanceApp extends StatelessWidget {
//   const AttendanceApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AttendancePage(),
//     );
//   }
// }

// class AttendancePage extends StatefulWidget {
//   const AttendancePage({super.key});

//   @override
//   State<AttendancePage> createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage> {
//   final DatabaseReference dbRef = FirebaseDatabase.instance
//       .refFromURL("https://activeloaninfo-default-rtdb.firebaseio.com/registration");
//   int attendanceCount = 0;
//   String searchQuery = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.only(right: 16),
//               child: Text(
//                 "Attended: $attendanceCount",
//                 style: const TextStyle(fontSize: 18),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => setState(() {
//               searchQuery = "";
//             }),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               decoration: const InputDecoration(
//                 labelText: "Search by Name",
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (val) {
//                 setState(() {
//                   searchQuery = val.trim().toLowerCase();
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder(
//               stream: dbRef.onValue,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final event = snapshot.data as DatabaseEvent;
//                 final map = event.snapshot.value as Map?;
//                 if (map == null || map.isEmpty) {
//                   attendanceCount = 0;
//                   return const Center(
//                     child: Text(
//                       "No attendance rows available.",
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   );
//                 }

//                 // Count submitted rows
//                 attendanceCount = map.values
//                     .where((row) => (row as Map)["submitted"] == true)
//                     .length;

//                 // Only show rows where submitted = false
//                 final rowsToShow = map.entries
//                     .where((entry) => (entry.value as Map)["submitted"] != true)
//                     .toList();

//                 // Filter by Name search
//                 final filteredRows = rowsToShow.where((entry) {
//                   final value = entry.value as Map;
//                   final name = (value["name"] ?? "").toString().toLowerCase();
//                   return name.contains(searchQuery);
//                 }).toList();

//                 if (filteredRows.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No rows match the search.",
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredRows.length,
//                   itemBuilder: (context, index) {
//                     final key = filteredRows[index].key;
//                     final value = filteredRows[index].value as Map;
//                     final bike = value["bike"] ?? "";
//                     final name = value["name"] ?? "";
//                     final colC = value["colC"] ?? "";
//                     final colD = value["colD"] ?? "";
//                     final submitted = value["submitted"] ?? false;

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text("$bike - $name"),
//                         subtitle: Text("C: $colC | D: $colD"),
//                         trailing: ElevatedButton(
//                           child: Text(submitted ? "Submitted" : "Submit"),
//                           onPressed: submitted
//                               ? null
//                               : () async {
//                                   await dbRef.child(key!).update({"submitted": true});
//                                   setState(() {});
//                                 },
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final confirm = await showDialog<bool>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text("Unsubmit All"),
//               content: const Text(
//                   "Are you sure you want to unsubmit all submitted rows?"),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   child: const Text("Yes"),
//                 ),
//               ],
//             ),
//           );

//           if (confirm == true) {
//             final snapshot = await dbRef.get();
//             final map = snapshot.value as Map?;
//             if (map != null) {
//               for (final key in map.keys) {
//                 final row = map[key] as Map;
//                 if (row["submitted"] == true) {
//                   await dbRef.child(key).update({"submitted": false});
//                 }
//               }
//               setState(() {}); // refresh UI
//             }
//           }
//         },
//         child: const Icon(Icons.undo),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
//     );
//   }
// }






//################
//WITHOUT UNSUBMIT
//################



// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//       apiKey: "AIzaSyDOW8N1YFF2s44L5FFQxAZP4Grt84LRa70",
//       authDomain: "activeloaninfo.firebaseapp.com",
//       databaseURL: "https://activeloaninfo-default-rtdb.firebaseio.com",
//       projectId: "activeloaninfo",
//       storageBucket: "activeloaninfo.firebasestorage.app",
//       messagingSenderId: "689636555223",
//       appId: "1:689636555223:web:ce9883375a92238b443392",
//       measurementId: "G-H9XPKJHWT0",
//     ),
//   );

//   runApp(const AttendanceApp());
// }

// class AttendanceApp extends StatelessWidget {
//   const AttendanceApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AttendancePage(),
//     );
//   }
// }

// class AttendancePage extends StatefulWidget {
//   const AttendancePage({super.key});

//   @override
//   State<AttendancePage> createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage> {
//   final DatabaseReference dbRef = FirebaseDatabase.instance
//       .refFromURL("https://activeloaninfo-default-rtdb.firebaseio.com/registration");
//   int attendanceCount = 0;
//   String searchQuery = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.only(right: 16),
//               child: Text(
//                 "Attended: $attendanceCount",
//                 style: const TextStyle(fontSize: 18),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => setState(() {
//               searchQuery = "";
//             }),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               decoration: const InputDecoration(
//                 labelText: "Search by Name",
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (val) {
//                 setState(() {
//                   searchQuery = val.trim().toLowerCase();
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder(
//               stream: dbRef.onValue,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final event = snapshot.data as DatabaseEvent;
//                 final map = event.snapshot.value as Map?;
//                 if (map == null || map.isEmpty) {
//                   attendanceCount = 0; // no submitted rows
//                   return const Center(
//                     child: Text(
//                       "No attendance rows available.",
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   );
//                 }

//                 // ✅ Count all submitted rows (submitted = true)
//                 attendanceCount = map.values
//                     .where((row) => (row as Map)["submitted"] == true)
//                     .length;

//                 // Only show rows where submitted = false
//                 final rowsToShow = map.entries
//                     .where((entry) => (entry.value as Map)["submitted"] != true)
//                     .toList();

//                 // Filter by Name search
//                 final filteredRows = rowsToShow.where((entry) {
//                   final value = entry.value as Map;
//                   final name = (value["name"] ?? "").toString().toLowerCase();
//                   return name.contains(searchQuery);
//                 }).toList();

//                 if (filteredRows.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No rows match the search.",
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredRows.length,
//                   itemBuilder: (context, index) {
//                     final key = filteredRows[index].key;
//                     final value = filteredRows[index].value as Map;
//                     final bike = value["bike"] ?? "";
//                     final name = value["name"] ?? "";
//                     final colC = value["colC"] ?? "";
//                     final colD = value["colD"] ?? "";
//                     final submitted = value["submitted"] ?? false;

//                     return Card(
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text("$bike - $name"),
//                         subtitle: Text("C: $colC | D: $colD"),
//                         trailing: ElevatedButton(
//                           child: Text(submitted ? "Submitted" : "Submit"),
//                           onPressed: submitted
//                               ? null
//                               : () async {
//                                   // ✅ Update Firebase node to submitted = true
//                                   await dbRef.child(key!).update({"submitted": true});
//                                   setState(() {}); // refresh the list
//                                 },
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }