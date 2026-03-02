import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/people/v1.dart' as people;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spendly/features/cloud_sync/domain/entities/cloud_sync_state.dart';
import 'package:spendly/features/cloud_sync/domain/entities/google_profile_entity.dart';
import 'package:spendly/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  CloudSyncRepositoryImpl(this._ref);

  static const _metaFileName = 'cloud_sync_meta.json';
  static const _driveFolderName = 'Spendly';
  static const _backupFileName = 'spendly_backup.json';

  final Ref _ref;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/userinfo.profile',
      'email',
    ],
  );

  @override
  Future<CloudSyncState> loadState() async {
    final meta = await _readMeta();
    GoogleSignInAccount? account;
    try {
      account =
          _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently().timeout(
            const Duration(seconds: 4),
          );
    } catch (_) {
      account = _googleSignIn.currentUser;
    }

    return CloudSyncState(
      isConnected: (account?.email ?? meta.connectedEmail) != null,
      connectedEmail: account?.email ?? meta.connectedEmail,
      automaticDailyBackup: meta.automaticDailyBackup,
      lastBackupAt: meta.lastBackupAt,
    );
  }

  @override
  Future<CloudSyncState> connectAccount() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Sign in cancelled');
    }
    final current = await loadState();
    await _writeMeta(
      _CloudSyncMeta(
        automaticDailyBackup: current.automaticDailyBackup,
        lastBackupAt: current.lastBackupAt,
        connectedEmail: account.email,
      ),
    );
    return current.copyWith(isConnected: true, connectedEmail: account.email);
  }

  @override
  Future<CloudSyncState> disconnectAccount() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }

    final current = await loadState();
    await _writeMeta(
      _CloudSyncMeta(
        automaticDailyBackup: false,
        lastBackupAt: current.lastBackupAt,
        connectedEmail: null,
      ),
    );

    return current.copyWith(
      isConnected: false,
      clearConnectedEmail: true,
      automaticDailyBackup: false,
      isProcessing: false,
    );
  }

  @override
  Future<GoogleProfileEntity?> fetchGoogleProfile() async {
    // Avoid a second interactive prompt right after connect flow.
    final account = await _ensureAuthenticatedAccount(
      interactiveIfNeeded: false,
    );
    if (account == null) {
      return null;
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      return GoogleProfileEntity(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    }

    try {
      final api = people.PeopleServiceApi(client);
      final person = await api.people.get(
        'people/me',
        personFields: 'names,photos',
      );
      final name = person.names?.isNotEmpty == true
          ? person.names!.first.displayName
          : null;
      final photo = person.photos?.isNotEmpty == true
          ? person.photos!.first.url
          : null;
      return GoogleProfileEntity(
        email: account.email,
        displayName: name,
        photoUrl: photo,
      );
    } catch (_) {
      return GoogleProfileEntity(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    }
  }

  @override
  Future<CloudSyncState> setAutomaticDailyBackup(bool enabled) async {
    final current = await loadState();
    await _writeMeta(
      _CloudSyncMeta(
        automaticDailyBackup: enabled,
        lastBackupAt: current.lastBackupAt,
        connectedEmail: current.connectedEmail,
      ),
    );
    return current.copyWith(automaticDailyBackup: enabled);
  }

  @override
  Future<CloudSyncState> backupNow() async {
    final current = await loadState();
    if (!current.isConnected) {
      throw Exception('Not connected');
    }

    final account = await _ensureAuthenticatedAccount(
      interactiveIfNeeded: true,
    );
    if (account == null) {
      throw Exception('Authentication failed');
    }
    final payload = await _ref.read(settingsRepositoryProvider).exportJson();
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Authentication failed');
    }
    final api = drive.DriveApi(client);
    final folderId = await _getOrCreateSpendlyFolder(api);
    final existingFile = await _findBackupFile(api, folderId);
    final bytes = utf8.encode(payload);
    final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);

    if (existingFile?.id != null) {
      await api.files.update(
        drive.File(modifiedTime: DateTime.now(), name: _backupFileName),
        existingFile!.id!,
        uploadMedia: media,
      );
    } else {
      await api.files.create(
        drive.File(
          name: _backupFileName,
          parents: <String>[folderId],
          mimeType: 'application/json',
        ),
        uploadMedia: media,
      );
    }

    final backupAt = DateTime.now();
    await _writeMeta(
      _CloudSyncMeta(
        automaticDailyBackup: current.automaticDailyBackup,
        lastBackupAt: backupAt,
        connectedEmail: account.email,
      ),
    );
    return current.copyWith(
      isConnected: true,
      connectedEmail: account.email,
      lastBackupAt: backupAt,
    );
  }

  @override
  Future<void> restoreFromDrive() async {
    final current = await loadState();
    if (!current.isConnected) {
      throw Exception('Not connected');
    }

    await _ensureAuthenticatedAccount(interactiveIfNeeded: true);
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Authentication failed');
    }
    final api = drive.DriveApi(client);
    final folderId = await _getOrCreateSpendlyFolder(api);
    final backup = await _findBackupFile(api, folderId);
    if (backup?.id == null) {
      throw Exception('Backup not found');
    }

    final media = await api.files.get(
      backup!.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (media is! drive.Media) {
      throw Exception('Invalid backup payload');
    }
    final bytes = await media.stream.expand((chunk) => chunk).toList();
    final payload = utf8.decode(bytes);
    await _ref.read(settingsRepositoryProvider).importJson(payload);
  }

  @override
  Future<void> runDailyBackupIfNeeded() async {
    try {
      final state = await loadState();
      if (!state.isConnected || !state.automaticDailyBackup) {
        return;
      }

      final now = DateTime.now();
      final last = state.lastBackupAt;
      if (last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        return;
      }

      final account = await _ensureAuthenticatedAccount(
        interactiveIfNeeded: false,
      );
      if (account == null) {
        return;
      }

      await backupNow();
    } catch (_) {
      return;
    }
  }

  Future<String> _getOrCreateSpendlyFolder(drive.DriveApi api) async {
    final existing = await api.files.list(
      q:
          "mimeType = 'application/vnd.google-apps.folder' and "
          "name = '$_driveFolderName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id,name)',
      pageSize: 1,
    );

    final folder = existing.files?.isNotEmpty == true
        ? existing.files!.first
        : null;
    if (folder?.id != null) {
      return folder!.id!;
    }

    final created = await api.files.create(
      drive.File(
        name: _driveFolderName,
        mimeType: 'application/vnd.google-apps.folder',
      ),
      $fields: 'id',
    );

    if (created.id == null) {
      throw Exception('Could not create folder');
    }
    return created.id!;
  }

  Future<drive.File?> _findBackupFile(
    drive.DriveApi api,
    String folderId,
  ) async {
    final result = await api.files.list(
      q:
          "name = '$_backupFileName' and "
          "'$folderId' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 1,
    );
    if (result.files?.isEmpty ?? true) {
      return null;
    }
    return result.files!.first;
  }

  Future<File> _metaFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _metaFileName));
  }

  Future<_CloudSyncMeta> _readMeta() async {
    final file = await _metaFile();
    if (!await file.exists()) {
      return const _CloudSyncMeta(
        automaticDailyBackup: false,
        lastBackupAt: null,
        connectedEmail: null,
      );
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final lastBackupAtMs = json['lastBackupAtMs'] as int?;
      return _CloudSyncMeta(
        automaticDailyBackup: json['automaticDailyBackup'] as bool? ?? false,
        lastBackupAt: lastBackupAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastBackupAtMs),
        connectedEmail: json['connectedEmail'] as String?,
      );
    } catch (_) {
      return const _CloudSyncMeta(
        automaticDailyBackup: false,
        lastBackupAt: null,
        connectedEmail: null,
      );
    }
  }

  Future<void> _writeMeta(_CloudSyncMeta meta) async {
    final file = await _metaFile();
    final payload = <String, dynamic>{
      'automaticDailyBackup': meta.automaticDailyBackup,
      'lastBackupAtMs': meta.lastBackupAt?.millisecondsSinceEpoch,
      'connectedEmail': meta.connectedEmail,
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<GoogleSignInAccount?> _ensureAuthenticatedAccount({
    required bool interactiveIfNeeded,
  }) async {
    final current = _googleSignIn.currentUser;
    if (current != null) {
      return current;
    }

    try {
      final silent = await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 4),
      );
      if (silent != null) {
        return silent;
      }
    } catch (_) {
      // Ignore and fall through.
    }

    if (!interactiveIfNeeded) {
      return null;
    }

    return _googleSignIn.signIn();
  }
}

class _CloudSyncMeta {
  const _CloudSyncMeta({
    required this.automaticDailyBackup,
    required this.lastBackupAt,
    required this.connectedEmail,
  });

  final bool automaticDailyBackup;
  final DateTime? lastBackupAt;
  final String? connectedEmail;
}

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  return CloudSyncRepositoryImpl(ref);
});
