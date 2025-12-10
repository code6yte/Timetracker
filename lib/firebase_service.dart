import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'notes';

  // Create - Add a new note
  Future<void> addNote(String title, String description) async {
    try {
      await _firestore.collection(_collectionName).add({
        'title': title,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error adding note: $e');
      rethrow;
    }
  }

  // Read - Fetch all notes as stream
  Stream<List<Map<String, dynamic>>> getNotes() {
    return _firestore.collection(_collectionName).orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'] ?? '',
          'description': doc['description'] ?? '',
          'timestamp': doc['timestamp'] ?? 0,
        };
      }).toList();
    });
  }

  // Update - Modify an existing note
  Future<void> updateNote(String id, String title, String description) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'title': title,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  // Delete - Remove a note
  Future<void> deleteNote(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  // Read - Get a single note
  Future<Map<String, dynamic>?> getNote(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return {
          'id': id,
          'title': doc['title'],
          'description': doc['description'],
          'timestamp': doc['timestamp'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting note: $e');
      rethrow;
    }
  }
}
