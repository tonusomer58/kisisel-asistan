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

  // Update Profile (Name & Avatar)
  Future<void> updateProfile(String fullName, int seed) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'avatarSeed': seed,
    }, SetOptions(merge: true));
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
  Future<void> addTransaction(String title, double amount, String type, {String category = 'Diğer', DateTime? date, bool isFixedExpense = false}) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('transactions').add({
      'title': title,
      'amount': amount,
      'type': type, // 'income' or 'expense'
      'category': type == 'expense' ? category : null,
      'createdAt': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
      'isFixedExpense': isFixedExpense,
    });
  }

  // Get Transactions Stream
  Stream<QuerySnapshot> getTransactionsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete Transaction
  Future<void> deleteTransaction(String id) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('transactions').doc(id).delete();
  }

  // Restore Transaction
  Future<void> restoreTransaction(String id, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('transactions').doc(id).set(data);
  }

  // Delete Goal
  Future<void> deleteGoal(String id) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('goals').doc(id).delete();
  }

  // Add Chat Message
  Future<void> addChatMessage(String text, bool isUser) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('chats').add({
      'text': text,
      'isUser': isUser,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Chats Stream
  Stream<QuerySnapshot> getChatsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Clear Chat History
  Future<void> clearChat() async {
    if (uid.isEmpty) return;
    final snapshot = await _firestore.collection('users').doc(uid).collection('chats').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // --- ESNAF / KOBİ ÖZELLİKLERİ ---

  // Get Bills Stream
  Stream<QuerySnapshot> getBillsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  // Add Bill
  Future<void> addBill(String title, double amount, DateTime dueDate) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('bills').add({
      'title': title,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Pay Bill (Adds to transactions and deletes bill)
  Future<void> payBill(String id, String title, double amount) async {
    if (uid.isEmpty) return;
    await addTransaction(title, amount, 'expense', category: 'Fatura');
    await _firestore.collection('users').doc(uid).collection('bills').doc(id).delete();
  }

  // Get Fixed Expenses Stream
  Stream<QuerySnapshot> getFixedExpensesStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fixed_expenses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add Fixed Expense
  Future<void> addFixedExpense(String title, double amount) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('fixed_expenses').add({
      'title': title,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Fixed Expense
  Future<void> deleteFixedExpense(String id) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('fixed_expenses').doc(id).delete();
  }

  // Pay Fixed Expense (Adds to transactions under category 'Diger' or 'Sabit Gider', keeps in list)
  Future<void> payFixedExpense(String title, double amount) async {
    if (uid.isEmpty) return;
    await addTransaction('$title Ödemesi', amount, 'expense', category: 'Diğer', isFixedExpense: true);
  }

  // Get Upcoming Payments Stream
  Stream<QuerySnapshot> getUpcomingPaymentsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('upcoming_payments')
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  // Add Upcoming Payment
  Future<void> addUpcomingPayment(String title, double amount, DateTime dueDate) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('upcoming_payments').add({
      'title': title,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Upcoming Payment
  Future<void> deleteUpcomingPayment(String id) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('upcoming_payments').doc(id).delete();
  }

  // Get Reminders Stream
  Stream<QuerySnapshot> getRemindersStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .orderBy('date', descending: false)
        .snapshots();
  }

  // Add Reminder
  Future<void> addReminder(String title, DateTime date) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('reminders').add({
      'title': title,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Reminder
  Future<void> deleteReminder(String id) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('reminders').doc(id).delete();
  }
}
