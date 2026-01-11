import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';
import 'auth_service.dart';

class AppRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user ID
  String? get currentUserId => _authService.currentUser?.uid;

  // Collection reference
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Create a new task
  Future<String> createTask(Task task) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      DocumentReference docRef = await _tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks for current user as stream
  Stream<List<Task>> getUserTasks() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _tasksCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Get tasks filtered by category
  Stream<List<Task>> getTasksByCategory(String category) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _tasksCollection
        .where('userId', isEqualTo: currentUserId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Get completed tasks
  Stream<List<Task>> getCompletedTasks() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _tasksCollection
        .where('userId', isEqualTo: currentUserId)
        .where('completed', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Get pending tasks
  Stream<List<Task>> getPendingTasks() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _tasksCollection
        .where('userId', isEqualTo: currentUserId)
        .where('completed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _tasksCollection.doc(taskId).update(updates);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskComplete(String taskId, bool currentStatus) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'completed': !currentStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to toggle task: $e');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get single task
  Future<Task?> getTask(String taskId) async {
    try {
      DocumentSnapshot doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        return Task.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Batch create tasks (useful for initial setup or migration)
  Future<void> batchCreateTasks(List<Task> tasks) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var task in tasks) {
        DocumentReference docRef = _tasksCollection.doc();
        batch.set(docRef, task.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch create tasks: $e');
    }
  }

  // Get task count by status
  Future<Map<String, int>> getTaskCounts() async {
    if (currentUserId == null) {
      return {'pending': 0, 'completed': 0, 'total': 0};
    }

    try {
      QuerySnapshot allTasks = await _tasksCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      int total = allTasks.docs.length;
      int completed = allTasks.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['completed'] == true,
          )
          .length;
      int pending = total - completed;

      return {'pending': pending, 'completed': completed, 'total': total};
    } catch (e) {
      return {'pending': 0, 'completed': 0, 'total': 0};
    }
  }
}

// // Listen for updates
// final repo = Provider.of<AppRepository>(context);

// // Read without listening
// final repo = Provider.of<AppRepository>(context, listen: false);
