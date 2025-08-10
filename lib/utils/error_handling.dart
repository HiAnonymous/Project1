// lib/utils/error_handling.dart

String getErrorMessage(dynamic e) {
  if (e is String) {
    return e;
  }
  return 'An unexpected error occurred. Please try again later.';
} 