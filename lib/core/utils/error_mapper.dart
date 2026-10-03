import 'dart:developer' as developer;

// `firebase_auth` re-exports `FirebaseException`, so a separate
// `firebase_core`/`cloud_firestore` import is not required here.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;

/// A failure that is safe to show to a business user.
///
/// Spec section 27 requires that raw backend errors (`FirebaseError:
/// PERMISSION_DENIED`) never reach the interface, while the technical detail
/// is still logged for developers.
@immutable
class AppException implements Exception {
  const AppException({
    required this.userMessage,
    this.technicalMessage,
    this.code,
  });

  /// Plain-language message shown in the UI.
  final String userMessage;

  /// Original detail, for logs and debugging only. Never rendered.
  final String? technicalMessage;

  /// Stable identifier for the failure kind.
  final String? code;

  @override
  String toString() =>
      'AppException($code): $userMessage'
      '${technicalMessage == null ? '' : ' <- $technicalMessage'}';
}

/// Raised when a SKU is already claimed by another product (spec section 15).
class DuplicateSkuException extends AppException {
  const DuplicateSkuException(String sku)
    : super(
        userMessage: 'This SKU is already in use.',
        technicalMessage: 'Duplicate SKU claim: $sku',
        code: 'duplicate-sku',
      );
}

/// Raised when a barcode is already registered (spec section 15).
class DuplicateBarcodeException extends AppException {
  const DuplicateBarcodeException(String barcode)
    : super(
        userMessage: 'This barcode is already registered.',
        technicalMessage: 'Duplicate barcode claim: $barcode',
        code: 'duplicate-barcode',
      );
}

/// Raised when the document changed underneath the editor.
class ConcurrentModificationException extends AppException {
  const ConcurrentModificationException()
    : super(
        userMessage:
            'Someone else changed this item while you were editing. '
            'Please reload and try again.',
        code: 'concurrent-modification',
      );
}

/// Raised when a requested document no longer exists.
class NotFoundException extends AppException {
  const NotFoundException()
    : super(
        userMessage: "We couldn't find that item. It may have been removed.",
        code: 'not-found',
      );
}

/// Fallback messages keyed by the action the user was attempting, so the
/// message is always specific rather than a generic "something went wrong".
class ErrorMessages {
  const ErrorMessages._();

  static const String loadProducts =
      "We couldn't load your products. Please check your connection and try "
      'again.';
  static const String loadCategories =
      "We couldn't load your categories. Please check your connection and try "
      'again.';
  static const String saveProduct =
      "We couldn't save this product. Please check your connection and try "
      'again.';
  static const String loadProduct =
      "We couldn't load this product. Please check your connection and try "
      'again.';
  static const String saveCategory =
      "We couldn't save this category. Please check your connection and try "
      'again.';
  static const String updateStatus =
      "We couldn't update this product's status. Please try again.";
  static const String uploadImage =
      "We couldn't upload the image. Please try again.";
  static const String signIn = "We couldn't sign you in. Please try again.";

  static const String noPermission =
      "You don't have permission to perform this action.";
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String unreachable =
      "We couldn't reach the server. Please check your connection and try "
      'again.';
  static const String tooManyRequests =
      'Too many requests right now. Please try again shortly.';
  static const String malformedResponse =
      'Something went wrong while reading your data. Please try again.';
}

/// Unwraps Riverpod 3's [ProviderException].
///
/// Riverpod wraps anything a provider throws, so the original exception has to
/// be unwrapped before it can be mapped (nesting is possible when a provider
/// fails because a dependency failed).
Object unwrapError(Object error) {
  if (error is ProviderException) return unwrapError(error.exception);
  return error;
}

/// Converts any thrown object into a user-safe [AppException].
///
/// [fallbackMessage] should come from [ErrorMessages] and describe the action
/// the user was attempting.
AppException mapError(Object error, {required String fallbackMessage}) {
  final Object unwrapped = unwrapError(error);

  if (unwrapped is AppException) return unwrapped;

  if (unwrapped is FirebaseException) {
    return AppException(
      userMessage: _messageForFirebaseCode(unwrapped.code, fallbackMessage),
      technicalMessage: unwrapped.message,
      code: unwrapped.code,
    );
  }

  if (unwrapped is FirebaseAuthException) {
    return AppException(
      userMessage: _messageForAuthCode(unwrapped.code, fallbackMessage),
      technicalMessage: unwrapped.message,
      code: unwrapped.code,
    );
  }

  return AppException(
    userMessage: fallbackMessage,
    technicalMessage: unwrapped.toString(),
  );
}

String _messageForFirebaseCode(String code, String fallback) => switch (code) {
  'permission-denied' => ErrorMessages.noPermission,
  'unauthenticated' => ErrorMessages.sessionExpired,
  'unavailable' ||
  'deadline-exceeded' ||
  'network-request-failed' => ErrorMessages.unreachable,
  'not-found' || 'document-missing' => ErrorMessages.malformedResponse,
  'already-exists' || 'aborted' => ErrorMessages.tooManyRequests,
  'resource-exhausted' => ErrorMessages.tooManyRequests,
  'data-loss' => ErrorMessages.malformedResponse,
  _ => fallback,
};

String _messageForAuthCode(String code, String fallback) => switch (code) {
  'invalid-email' => 'Enter a valid email address.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'Incorrect email or password.',
  'user-disabled' => 'This account has been disabled. Contact your owner.',
  'too-many-requests' => ErrorMessages.tooManyRequests,
  'network-request-failed' => ErrorMessages.unreachable,
  'email-already-in-use' => 'An account already exists for this email.',
  'weak-password' => 'Choose a stronger password.',
  'operation-not-allowed' => 'Email sign-in is not enabled for this project.',
  _ => fallback,
};

/// Logs the technical detail of a failure for developers without leaking it
/// into the interface.
void logError(
  Object error,
  StackTrace? stackTrace, {
  String context = 'mambopoint',
  Map<String, Object?>? data,
}) {
  if (!kDebugMode) return;
  developer.log(
    '$context: $error${data == null ? '' : ' | $data'}',
    name: 'mambopoint',
    error: error,
    stackTrace: stackTrace,
  );
}
