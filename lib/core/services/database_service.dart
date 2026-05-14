import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // Add Goal
  Future<void> addGoal(String name, double target) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('goals').add({
      'name': name,
      'target': target,
      'current': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Goal Funds
  Future<void> addFundsToGoal(String goalId, double amount) async {
    if (uid.isEmpty) return;
    final goalRef = _firestore.collection('users').doc(uid).collection('goals').doc(goalId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(goalRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final double current = (data['current'] ?? 0.0).toDouble();
      final double target = (data['target'] ?? 0.0).toDouble();
      
      double newCurrent = current + amount;
      if (newCurrent > target) newCurrent = target;

      transaction.update(goalRef, {'current': newCurrent});
    });
  }

  // Get Goals Stream
  Stream<QuerySnapshot> getGoalsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add Transaction (Income/Expense)
  Future<void> addTransaction(String title, double amount, String type) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('transactions').add({
      'title': title,
      'amount': amount,
      'type': type, // 'income' or 'expense'
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Transactions Stream
  Stream<QuerySnapshot> getTransactionsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .snapshots();
  }
}
