import 'dart:io';

class NetworkInfo {
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('localhost');
      return result.isNotEmpty && result.any((addr) => addr.rawAddress.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  Stream<bool> get onConnectivityChanged {
    return Stream.periodic(const Duration(seconds: 10), (_) => true).asyncMap((_) => isConnected);
  }
}
