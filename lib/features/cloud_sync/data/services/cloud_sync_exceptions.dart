class CloudSyncException implements Exception {
  const CloudSyncException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class CloudSyncAuthException extends CloudSyncException {
  const CloudSyncAuthException(super.message, {super.cause});
}

class CloudSyncBackupNotFoundException extends CloudSyncException {
  const CloudSyncBackupNotFoundException(super.message, {super.cause});
}

class CloudSyncCorruptedBackupException extends CloudSyncException {
  const CloudSyncCorruptedBackupException(super.message, {super.cause});
}

class CloudSyncDriveException extends CloudSyncException {
  const CloudSyncDriveException(super.message, {super.cause});
}

class CloudSyncNetworkException extends CloudSyncException {
  const CloudSyncNetworkException(super.message, {super.cause});
}
