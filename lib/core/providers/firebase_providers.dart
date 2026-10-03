import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase service instances behind providers.
///
/// Every layer takes its SDK instance from here rather than calling
/// `FirebaseFirestore.instance` directly, so tests and the emulator can swap
/// implementations through `ProviderScope(overrides: [...])` without touching
/// widget or notifier code.

final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final Provider<FirebaseFirestore> firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final Provider<FirebaseStorage> firebaseStorageProvider =
    Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

/// Emits whenever the signed-in user changes (sign in, sign out, token
/// refresh).
final StreamProvider<User?> authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);
