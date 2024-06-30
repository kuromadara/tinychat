import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/common/common.dart';

class SessionManagerService {
  late FlutterSecureStorage secureStorage;

  SessionManagerService() {
    secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ));
  }

  Future<void> deleteAll() async {
    await secureStorage.deleteAll();
  }

  Future<void> saveUserFullName(String? userName) async {
    await secureStorage.write(key: keyUserName, value: userName);
  }

  Future<String?> getUserName() async {
    return await secureStorage.read(key: keyUserName);
  }

  Future<void> saveDownloadStatus(String status) async {
    await secureStorage.write(key: downloadStatus, value: status);
  }

  Future<String?> getDownloadStatus() async {
    return await secureStorage.read(key: downloadStatus);
  }

  // delete download status
  Future<void> deleteDownloadStatus() async {
    await secureStorage.delete(key: downloadStatus);
  }
}
