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
  NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for authentication errors
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for Firestore/database errors
class DatabaseException extends AppException {
  DatabaseException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for validation errors
class ValidationException extends AppException {
  ValidationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for AI/Gemini service errors
class AIServiceException extends AppException {
  AIServiceException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for OTP-related errors
class OTPException extends AppException {
  OTPException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception for storage/file errors
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
