
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';
import '../models/plant_model.dart';
import '../models/recipe_model.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import 'auth_database.dart';

class FirebaseService {
  static bool _isFirebaseInitialized = false;

  static bool get isFirebaseInitialized =>
      _isFirebaseInitialized || Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseStorage get _storage => FirebaseStorage.instance;

  // ==========================================
  // 1. FIREBASE INITIALIZATION
  // ==========================================

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _isFirebaseInitialized = true;

      debugPrint('Firebase initialized successfully!');
      debugPrint(
        'Firebase project: ${Firebase.app().options.projectId}',
      );
    } catch (e, stackTrace) {
      _isFirebaseInitialized = false;

      debugPrint('FIREBASE INITIALIZATION FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  // ==========================================
  // 2. REGISTER USER
  // ==========================================

  Future<AuthResult> registerWithFirebase({
    required String name,
    required String email,
    required String password,
    required String municipality,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Community users cannot register themselves as administrators.
    final safeRole = role == UserRole.administrator
        ? UserRole.communityMember
        : role;

    if (!isFirebaseInitialized) {
      return const AuthResult(
        success: false,
        errorMessage: 'Firebase is not initialized.',
      );
    }

    User? createdUser;

    try {
      // Create Firebase Authentication account.
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'Failed to create user account.',
        );
      }

      // Update display name.
      await createdUser.updateDisplayName(name.trim());

      // Prepare user information.
      final userData = {
        'uid': createdUser.uid,
        'name': name.trim(),
        'email': normalizedEmail,
        'municipality': municipality.trim().isEmpty
            ? 'Virac'
            : municipality.trim(),
        'role': safeRole == UserRole.administrator ? 'admin' : 'user',
        'isEmailVerified': false,
        'favorites': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save user information to Cloud Firestore.
      try {
        await _firestore
            .collection('users')
            .doc(createdUser.uid)
            .set(userData);

        debugPrint(
          'USER SAVED TO FIRESTORE: ${createdUser.uid}',
        );
      } on FirebaseException catch (e) {
        debugPrint(
          'FIRESTORE SAVE ERROR: ${e.code} - ${e.message}',
        );

        // Attempt cleanup if Firestore profile creation fails.
        try {
          await createdUser.delete();
        } catch (deleteError) {
          debugPrint(
            'AUTH CLEANUP ERROR: $deleteError',
          );
        }

        return AuthResult(
          success: false,
          errorMessage:
              'Your account could not be saved to the database: ${e.message}',
        );
      }

      // Send email verification.
      try {
        await createdUser.sendEmailVerification();
        debugPrint('VERIFICATION EMAIL SENT');
      } catch (e) {
        debugPrint('VERIFICATION EMAIL ERROR: $e');
      }

      // Create local user account object.
      final account = UserAccount(
        id: createdUser.uid,
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: '[FIREBASE_SECURE_MANAGED]',
        passwordSalt: '[FIREBASE_SECURE_MANAGED]',
        municipality: municipality.trim().isEmpty
            ? 'Virac'
            : municipality.trim(),
        role: safeRole,
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );

      return AuthResult(
        success: true,
        user: account,
        requiresVerification: true,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FIREBASE AUTH ERROR: ${e.code} - ${e.message}',
      );

      return AuthResult(
        success: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e, stackTrace) {
      debugPrint('REGISTRATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      return AuthResult(
        success: false,
        errorMessage: 'Registration error: $e',
      );
    }
  }

  // ==========================================
  // 3. LOGIN USER
  // ==========================================

  Future<AuthResult> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!isFirebaseInitialized) {
      return const AuthResult(
        success: false,
        errorMessage: 'Firebase is not initialized.',
      );
    }

    try {
      // Authenticate user.
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'Invalid user credentials.',
        );
      }

      // Reload user information.
      await user.reload();

      final freshUser = _auth.currentUser ?? user;

      // Get user profile from Firestore.
      final doc = await _firestore
          .collection('users')
          .doc(freshUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const AuthResult(
          success: false,
          errorMessage:
              'User profile not found in Firestore. Please contact the administrator.',
        );
      }

      final data = doc.data()!;

      final roleStr = data['role'] as String?;

      final resolvedRole = (roleStr == 'admin' || roleStr == 'administrator')
          ? UserRole.administrator
          : UserRole.communityMember;

      final municipality =
          data['municipality'] as String? ?? 'Virac';

      final adminId = data['adminId'] as String? ?? '';

      // Create account object.
      final account = UserAccount(
        id: freshUser.uid,
        name: data['name'] as String? ??
            freshUser.displayName ??
            freshUser.email?.split('@').first ??
            'Explorer',
        email: freshUser.email ?? normalizedEmail,
        passwordHash: '[FIREBASE_SECURE_MANAGED]',
        passwordSalt: '[FIREBASE_SECURE_MANAGED]',
        municipality: municipality,
        role: resolvedRole,
        adminId: adminId,
        isEmailVerified: freshUser.emailVerified,
        createdAt: freshUser.metadata.creationTime ??
            DateTime.now(),
      );

      debugPrint(
        'USER LOGIN SUCCESSFUL: ${freshUser.uid}',
      );

      return AuthResult(
        success: true,
        user: account,
        requiresVerification: !freshUser.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LOGIN AUTH ERROR: ${e.code} - ${e.message}',
      );

      return AuthResult(
        success: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'LOGIN FIRESTORE ERROR: ${e.code} - ${e.message}',
      );

      return AuthResult(
        success: false,
        errorMessage:
            'Unable to retrieve your user profile: ${e.message}',
      );
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      return AuthResult(
        success: false,
        errorMessage: 'Authentication error: $e',
      );
    }
  }

  // ==========================================
  // 4. SEND EMAIL VERIFICATION
  // ==========================================

  Future<VerificationResult>
      sendFirebaseEmailVerification() async {
    if (!isFirebaseInitialized) {
      return const VerificationResult(
        success: false,
        message: 'Firebase is not initialized.',
      );
    }

    final user = _auth.currentUser;

    if (user == null) {
      return const VerificationResult(
        success: false,
        message: 'No active user session found.',
      );
    }

    try {
      await user.sendEmailVerification();

      return const VerificationResult(
        success: true,
        message:
            'A verification link has been sent by Firebase to your email address.',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult(
        success: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      debugPrint('EMAIL VERIFICATION ERROR: $e');

      return VerificationResult(
        success: false,
        message: 'Unable to send verification email: $e',
      );
    }
  }

  // ==========================================
  // 5. CHECK EMAIL VERIFICATION
  // ==========================================

  Future<bool> reloadAndCheckVerification() async {
    if (!isFirebaseInitialized) return false;

    final user = _auth.currentUser;

    if (user == null) return false;

    try {
      await user.reload();

      final freshUser = _auth.currentUser;

      final isVerified = freshUser?.emailVerified ?? false;

      if (isVerified && freshUser != null) {
        try {
          await _firestore
              .collection('users')
              .doc(freshUser.uid)
              .update({
            'isEmailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });

          debugPrint('EMAIL VERIFICATION STATUS UPDATED');
        } catch (e) {
          debugPrint(
            'FIRESTORE VERIFICATION UPDATE ERROR: $e',
          );
        }
      }

      return isVerified;
    } catch (e) {
      debugPrint('VERIFICATION CHECK ERROR: $e');
      return false;
    }
  }

  // ==========================================
  // 6. SEND PASSWORD RESET EMAIL
  // ==========================================

  Future<AuthResult> sendFirebasePasswordReset(
    String email,
  ) async {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(normalized)) {
      return const AuthResult(
        success: false,
        errorMessage: 'Please enter a valid email address.',
      );
    }

    if (!isFirebaseInitialized) {
      return const AuthResult(
        success: false,
        errorMessage: 'Firebase is not initialized.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: normalized,
      );

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      debugPrint('PASSWORD RESET ERROR: $e');

      return AuthResult(
        success: false,
        errorMessage: 'Unable to send password reset email: $e',
      );
    }
  }

  // ==========================================
  // 7. CONFIRM PASSWORD RESET
  // ==========================================

  Future<AuthResult> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    if (!isFirebaseInitialized) {
      return const AuthResult(
        success: false,
        errorMessage: 'Firebase is not initialized.',
      );
    }

    try {
      await _auth.confirmPasswordReset(
        code: code.trim(),
        newPassword: newPassword,
      );

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      debugPrint('PASSWORD RESET CONFIRMATION ERROR: $e');

      return AuthResult(
        success: false,
        errorMessage: 'Password reset error: $e',
      );
    }
  }

  // ==========================================
  // 8. SIGN OUT
  // ==========================================

  Future<void> signOut() async {
    if (isFirebaseInitialized) {
      await _auth.signOut();

      debugPrint('USER SIGNED OUT');
    }
  }

  // ==========================================
  // 9. FIREBASE AUTH ERROR HANDLER
  // ==========================================

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account registered with this email address. Please check your spelling or register.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';

      case 'email-already-in-use':
        return 'An account with this email address already exists. Please log in.';

      case 'weak-password':
        return 'The password is too weak. Please use at least 8 characters with numbers and symbols.';

      case 'invalid-email':
        return 'The email address format is invalid.';

      case 'too-many-requests':
        return 'Too many attempts. Access temporarily disabled. Please try again later.';

      case 'expired-action-code':
        return 'The verification or reset link has expired. Please request a new one.';

      case 'invalid-action-code':
        return 'The action code or link is invalid or has already been used.';

      case 'network-request-failed':
        return 'Network connection error. Please verify your internet connectivity.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';

      default:
        return e.message ??
            'An unexpected authentication error occurred.';
    }
  }

  // ==========================================
  // 10. HERBS (PLANTS) LIVE FIRESTORE CRUD
  // ==========================================

  Stream<List<Plant>> streamHerbs() {
    if (!isFirebaseInitialized) return const Stream.empty();
    return _firestore.collection('herbs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Plant.fromMap(doc.data(), docId: doc.id)).toList();
    });
  }

  Future<List<Plant>> getHerbs() async {
    if (!isFirebaseInitialized) return [];
    try {
      final snap = await _firestore.collection('herbs').get();
      if (snap.docs.isEmpty) {
        // Fallback or legacy plants collection check
        final legacySnap = await _firestore.collection('plants').get();
        if (legacySnap.docs.isNotEmpty) {
          return legacySnap.docs.map((doc) => Plant.fromMap(doc.data(), docId: doc.id)).toList();
        }
        return [];
      }
      return snap.docs.map((doc) => Plant.fromMap(doc.data(), docId: doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching herbs from Firestore: $e');
      return [];
    }
  }

  Future<void> saveHerb(Plant plant) async {
    if (!isFirebaseInitialized) return;
    final map = plant.toFirestoreMap();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('herbs').doc(plant.id).set(map, SetOptions(merge: true));
    await _firestore.collection('plants').doc(plant.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteHerb(String herbId) async {
    if (!isFirebaseInitialized) return;
    await _firestore.collection('herbs').doc(herbId).delete();
    await _firestore.collection('plants').doc(herbId).delete();
  }

  Future<void> updateHerbStock({
    required String herbId,
    required bool inStock,
    required int stockQuantity,
  }) async {
    if (!isFirebaseInitialized) return;
    await _firestore.collection('herbs').doc(herbId).update({
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // 11. RECIPES / GUIDES FIRESTORE CRUD
  // ==========================================

  Stream<List<HerbRecipe>> streamRecipes({String? herbId}) {
    if (!isFirebaseInitialized) return const Stream.empty();
    Query<Map<String, dynamic>> query = _firestore.collection('recipes');
    if (herbId != null && herbId.isNotEmpty) {
      query = query.where('herbId', isEqualTo: herbId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => HerbRecipe.fromMap(doc.data(), docId: doc.id)).toList();
    });
  }

  Future<List<HerbRecipe>> getRecipes({String? herbId}) async {
    if (!isFirebaseInitialized) return [];
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('recipes');
      if (herbId != null && herbId.isNotEmpty) {
        query = query.where('herbId', isEqualTo: herbId);
      }
      final snap = await query.get();
      return snap.docs.map((doc) => HerbRecipe.fromMap(doc.data(), docId: doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      return [];
    }
  }

  Future<void> saveRecipe(HerbRecipe recipe) async {
    if (!isFirebaseInitialized) return;
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteRecipe(String recipeId) async {
    if (!isFirebaseInitialized) return;
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  // ==========================================
  // 12. ORDERS FIRESTORE CRUD & STREAM
  // ==========================================

  Stream<List<HerbOrder>> streamUserOrders(String userId) {
    if (!isFirebaseInitialized || userId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HerbOrder.fromMap(doc.data(), docId: doc.id)).toList();
    });
  }

  Stream<List<HerbOrder>> streamAllOrders() {
    if (!isFirebaseInitialized) return const Stream.empty();
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => HerbOrder.fromMap(doc.data(), docId: doc.id)).toList();
    });
  }

  Future<String> createOrder(HerbOrder order) async {
    if (!isFirebaseInitialized) return order.id;
    final docRef = _firestore.collection('orders').doc(order.id);
    await docRef.set(order.toMap());
    return docRef.id;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    if (!isFirebaseInitialized) return;
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // 13. USER FAVORITES PERSISTENCE
  // ==========================================

  Future<void> syncFavorite({
    required String userId,
    required String herbId,
    required bool isFavorite,
  }) async {
    if (!isFirebaseInitialized || userId.isEmpty) return;
    try {
      final docRef = _firestore.collection('users').doc(userId);
      if (isFavorite) {
        await docRef.update({
          'favorites': FieldValue.arrayUnion([herbId]),
        });
      } else {
        await docRef.update({
          'favorites': FieldValue.arrayRemove([herbId]),
        });
      }
    } catch (e) {
      debugPrint('Error syncing favorites to Firestore: $e');
    }
  }

  Future<List<String>> fetchUserFavorites(String userId) async {
    if (!isFirebaseInitialized || userId.isEmpty) return [];
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return [];
      final list = doc.data()?['favorites'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  // ==========================================
  // 14. FIREBASE STORAGE IMAGE UPLOAD
  // ==========================================

  Future<String> uploadHerbImage({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase is not initialized.');
    }
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final ref = _storage.ref().child('herbs').child(uniqueName);
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: mimeType),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  // ==========================================
  // 15. ADMIN SUMMARY METRICS
  // ==========================================

  Future<Map<String, int>> getAdminMetrics() async {
    if (!isFirebaseInitialized) {
      return {'totalHerbs': 0, 'lowStock': 0, 'totalUsers': 0, 'totalOrders': 0};
    }
    try {
      final herbsSnap = await _firestore.collection('herbs').get();
      final totalHerbs = herbsSnap.docs.length;
      int lowStock = 0;
      for (final doc in herbsSnap.docs) {
        final data = doc.data();
        final inStock = data['inStock'] as bool? ?? true;
        final qty = (data['stockQuantity'] as num?)?.toInt() ?? 25;
        if (!inStock || qty <= 5) {
          lowStock++;
        }
      }

      final usersSnap = await _firestore.collection('users').get();
      final ordersSnap = await _firestore.collection('orders').get();

      return {
        'totalHerbs': totalHerbs,
        'lowStock': lowStock,
        'totalUsers': usersSnap.docs.length,
        'totalOrders': ordersSnap.docs.length,
      };
    } catch (e) {
      debugPrint('Error calculating metrics: $e');
      return {'totalHerbs': 0, 'lowStock': 0, 'totalUsers': 0, 'totalOrders': 0};
    }
  }
}
