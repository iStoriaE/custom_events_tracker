import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class NetworkManager {
  NetworkManager._privateConstructor();
  static final NetworkManager _instance = NetworkManager._privateConstructor();
  factory NetworkManager() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get networkStatusStream => _controller.stream;

  /// Call once (in TrackerService.initialize) to start listening.
  void initialize() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        _controller.add(NetworkStatus.online);
      } else {
        _controller.add(NetworkStatus.offline);
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
