import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '274807226246-pb369uv22g8r9siv509ed0dvfdqcar7l.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  AuthService(this._auth, this._firestore);

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await ensureUserHasBusiness();
    }
    return cred;
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name, {
    String? businessName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'name': name,
        'email': email,
        'role': 'BUSINESS_OWNER',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await createProductionBusiness(
        businessName: businessName != null && businessName.trim().isNotEmpty
            ? businessName.trim()
            : "$name's Organization",
      );
    }
    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    if (cred.user != null) {
      try {
        final userDocRef = _firestore.collection('users').doc(cred.user!.uid);
        final userDoc = await userDocRef.get();

        final userData = <String, dynamic>{
          'id': cred.user!.uid,
          'name': cred.user!.displayName ?? googleUser.displayName ?? 'Business User',
          'role': 'BUSINESS_OWNER',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final email = cred.user!.email ?? googleUser.email;
        if (email.isNotEmpty) {
          userData['email'] = email;
        }

        final photo = cred.user!.photoURL ?? googleUser.photoUrl;
        if (photo != null && (photo.startsWith('http://') || photo.startsWith('https://'))) {
          userData['avatarUrl'] = photo;
        }

        if (!userDoc.exists) {
          userData['createdAt'] = FieldValue.serverTimestamp();
          await userDocRef.set(userData);
        } else {
          await userDocRef.update(userData);
        }

        await ensureUserHasBusiness();
      } catch (err) {
        debugPrint('Warning: User profile sync failed: $err');
      }
    }
    return cred;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Ensures that the current authenticated user has an associated business.
  /// If none exists, creates a production business setup.
  Future<void> ensureUserHasBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final existingBiz = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingBiz.docs.isEmpty) {
        final bizName = user.displayName != null && user.displayName!.trim().isNotEmpty
            ? "${user.displayName!.trim()}'s Organization"
            : 'My Organization';
        await createProductionBusiness(businessName: bizName);
      }
    } catch (err) {
      debugPrint('Warning: ensureUserHasBusiness failed: $err');
    }
  }

  /// Creates a real production business with primary branch, default service, and counter.
  Future<String> createProductionBusiness({
    required String businessName,
    String? category,
    String? branchName,
    String? branchAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be authenticated to create a business.');

    final uid = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanUid = uid.length > 8 ? uid.substring(0, 8) : uid;
    final businessId = 'biz_${cleanUid}_$timestamp';
    final branchId = 'branch_$timestamp';
    const serviceId = 'service_1';
    const counterId = 'counter_1';

    final userEmail = (user.email != null && user.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : 'owner_$cleanUid@easyqueue.internal';

    // 1. First commit the Business and Owner Member
    final bizBatch = _firestore.batch();
    final bizRef = _firestore.collection('businesses').doc(businessId);
    bizBatch.set(bizRef, {
      'id': businessId,
      'name': businessName.trim(),
      'ownerId': uid,
      'category': category != null && category.trim().isNotEmpty ? category.trim() : 'GENERAL',
      if (user.email != null && user.email!.trim().isNotEmpty) 'email': user.email!.trim(),
      'isPublic': true,
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final memberRef = bizRef.collection('members').doc(uid);
    bizBatch.set(memberRef, {
      'id': uid,
      'businessId': businessId,
      'userId': uid,
      'displayName': user.displayName ?? businessName.trim(),
      'email': userEmail,
      'role': 'OWNER',
      'assignedBranchIds': [branchId],
      'assignedCounterIds': [counterId],
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await bizBatch.commit();

    // 2. Now commit Branch, Service, Counter (Business document already committed & exists)
    final branchBatch = _firestore.batch();
    final branchRef = bizRef.collection('branches').doc(branchId);
    branchBatch.set(branchRef, {
      'id': branchId,
      'businessId': businessId,
      'name': branchName != null && branchName.trim().isNotEmpty ? branchName.trim() : 'Main Branch',
      'code': 'MAIN',
      'address': branchAddress != null && branchAddress.trim().isNotEmpty ? branchAddress.trim() : 'Primary Facility',
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final serviceRef = branchRef.collection('services').doc(serviceId);
    branchBatch.set(serviceRef, {
      'id': serviceId,
      'branchId': branchId,
      'businessId': businessId,
      'name': 'General Service',
      'code': 'A',
      'estimatedDurationMinutes': 15,
      'status': 'ACTIVE',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final counterRef = branchRef.collection('counters').doc(counterId);
    branchBatch.set(counterRef, {
      'id': counterId,
      'branchId': branchId,
      'businessId': businessId,
      'counterNumber': 1,
      'name': 'Counter 1',
      'displayLabel': 'Counter 1',
      'supportedServiceIds': [serviceId],
      'assignedOperatorIds': [uid],
      'status': 'AVAILABLE',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await branchBatch.commit();

    // 6. Record default business on the user profile
    await _firestore.collection('users').doc(uid).set({
      'defaultBusinessId': businessId,
      'defaultBranchId': branchId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return businessId;
  }
}
