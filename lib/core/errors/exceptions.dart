/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Exception for network-related errors
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Exception for authentication errors
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

/// Exception for Firestore/database errors
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});
}

/// Exception for validation errors
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.originalError});
}

/// Exception for AI/Gemini service errors
class AIServiceException extends AppException {
  AIServiceException(super.message, {super.code, super.originalError});
}

/// Exception for OTP-related errors
class OTPException extends AppException {
  OTPException(super.message, {super.code, super.originalError});
}

/// Exception for storage/file errors
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});
}
