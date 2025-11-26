import 'package:cloud_firestore/cloud_firestore.dart';

/// MAANG-style repository for Firestore user data
/// - Keeps Firebase out of UI layer
/// - Efficient queries (single doc reads, not collection scans)
/// - Space efficient: only stores necessary data
///
/// Time complexity: O(1) for single doc operations
/// Space complexity: O(1) per user document
class UserRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference _usersRef;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _usersRef = _firestore.collection('users');
  }

  /// Create or update user document in Firestore
  /// Called after successful sign up
  /// Time: O(1) - single document write
  /// Space: O(1) - fixed size document
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    final data = {
      'email': email,
      'displayName': displayName ?? email.split('@')[0],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...?additionalData,
    };

    await _usersRef.doc(uid).set(
          data,
          SetOptions(merge: true), // Merge to avoid overwriting existing data
        );
  }

  /// Get user data as a one-time read
  /// Time: O(1) - single document read
  /// Space: O(1) - single document
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Stream user data (real-time updates)
  /// Subscribe to this for live user data
  /// Time: O(1) per update
  /// Space: O(1) - single listener
  Stream<Map<String, dynamic>?> userStream(String uid) {
    return _usersRef.doc(uid).snapshots().map(
          (doc) => doc.data() as Map<String, dynamic>?,
        );
  }

  /// Update specific fields in user document
  /// Time: O(1) - single document update
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await _usersRef.doc(uid).update({
      field: value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update multiple fields at once
  /// More efficient than multiple single-field updates
  /// Time: O(1) - single document update regardless of field count
  Future<void> updateUserFields(
      String uid, Map<String, dynamic> fields) async {
    await _usersRef.doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete user document
  /// Time: O(1) - single document delete
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  /// Check if user document exists
  /// Time: O(1) - single document read (cheaper than full get)
  Future<bool> userExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  /// Example: Get users by a field (use sparingly, prefer direct doc access)
  /// Time: O(n) where n = matching users - AVOID if possible
  /// Space: O(n) - stores all matching docs in memory
  /// NOTE: For MAANG-style performance, always use indexed queries
  /// and add pagination (limit/offset)
  Stream<List<Map<String, dynamic>>> getUsersByField(
    String field,
    dynamic value, {
    int limit = 10,
  }) {
    return _usersRef
        .where(field, isEqualTo: value)
        .limit(limit) // Always limit queries to avoid O(n) disasters
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'uid': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList(),
        );
  }
}

