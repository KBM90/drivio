class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}

class ServerErrorException implements Exception {
  final String message;
  ServerErrorException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}
