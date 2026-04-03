import 'package:firebase_database/firebase_database.dart';

class BranchConfig {
  static String branch = "";

  static DatabaseReference get dbRef =>
      FirebaseDatabase.instance.ref("registration/$branch");
}