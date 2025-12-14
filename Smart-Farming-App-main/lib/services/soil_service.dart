import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:farmer_app/models/soil_data.dart';

class SoilService {
  // Explicitly using the database URL because it's in a non-default region (asia-southeast1)
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://sihp-2025-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  SoilService() {
    print("DEBUG: SoilService initialized");
    print("DEBUG: Database URL: https://sihp-2025-default-rtdb.asia-southeast1.firebasedatabase.app");
    print("DEBUG: Reading from path: ${_dbRef.path}");
    print("DEBUG: Database key: ${_dbRef.key}");
  }

  Future<SoilData?> getLatestSoilData() async {
    try {
      // Reading from root as per valid assumption from screenshot
      // If the structure is complex, this will need adjustment.
      // We will try to read the values 'N', 'P', 'K' from the root.
      
      final snapshot = await _dbRef.get();
      
      if (snapshot.exists && snapshot.value is Map) {
        return SoilData.fromMap(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      // Return null to trigger fallback or error state UI
      return null;
    }
  }

  // Stream for real-time updates (Video recommended approach)
  Stream<SoilData?> getSoilStream() {
    return _dbRef.onValue.map((event) {
      print("DEBUG: Firebase Stream Event Received");
      print("DEBUG: Snapshot exists: ${event.snapshot.exists}");
      print("DEBUG: Snapshot value: ${event.snapshot.value}");
      print("DEBUG: Value type: ${event.snapshot.value.runtimeType}");
      
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = SoilData.fromMap(event.snapshot.value as Map);
        print("DEBUG: Parsed SoilData: $data");
        return data;
      }
      
      print("DEBUG: No data found in Firebase");
      return null;
    });
  }
}
