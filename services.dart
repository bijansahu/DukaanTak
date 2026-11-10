import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _a = FirebaseAuth.instance;
  String? _vid;
  int? _token;

  Future<void> sendOtp(String phone,
      {required VoidCallback onSent,
      required void Function(String) onError,
      VoidCallback? onAuto}) async {
    await _a.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 30),
      forceResendingToken: _token,
      verificationCompleted: (cred) async {
        await _a.signInWithCredential(cred); // instant / auto-retrieval
        onAuto?.call();
      },
      verificationFailed: (e) => onError(e.message ?? 'Could not send OTP'),
      codeSent: (id, token) {
        _vid = id;
        _token = token;
        onSent();
      },
      codeAutoRetrievalTimeout: (id) => _vid = id,
    );
  }

  Future<void> verify(String code) => _a.signInWithCredential(
      PhoneAuthProvider.credential(verificationId: _vid!, smsCode: code));

  Future<void> signOut() => _a.signOut();
}

class Db {
  final _f = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _f.collection('users').doc(uid);

  Future<Map<String, dynamic>?> getProfile(String uid) async =>
      (await _user(uid).get()).data();

  Future<void> saveProfile(String uid, Map<String, dynamic> d) =>
      _user(uid).set({...d, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  Future<String> placeOrder({
    required String uid,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> items,
    required int itemTotal,
    required int fee,
    required String payment, // 'upi' | 'cod'
  }) async {
    final ref = _f.collection('orders').doc();
    await ref.set({
      'customerId': uid,
      'customerName': profile['name'],
      'customerPhone': profile['phone'],
      'address': {
        'village': profile['village'],
        'landmark': profile['landmark'],
        'lat': profile['lat'],
        'lng': profile['lng'],
      },
      'items': items,
      'itemTotal': itemTotal,
      'deliveryFee': fee,
      'total': itemTotal + fee,
      'paymentMethod': payment,
      'paymentStatus': payment == 'cod' ? 'cash_on_delivery' : 'pending_online',
      'status': 'placed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String id) =>
      _f.collection('orders').doc(id).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> myOrders(String uid) =>
      _f.collection('orders').where('customerId', isEqualTo: uid).snapshots();

  Future<void> cancelOrder(String id) =>
      _f.collection('orders').doc(id).update({'status': 'cancelled'});

  Future<void> reportIssue(String orderId, String uid, String type) =>
      _f.collection('issues').add({
        'orderId': orderId,
        'customerId': uid,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
