import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static Future<bool> isConnected() async {
    var connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }
}
