

// // lib/services/connectivity_service.dart
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:async';
// import 'package:http/http.dart' as http;

// class ConnectivityService {
//   final Connectivity _connectivity = Connectivity();
//   late StreamController<bool> _connectionController;

//   ConnectivityService() {
//     _connectionController = StreamController<bool>();
//     _initConnectivityMonitoring();
//   }

//   void _initConnectivityMonitoring() {
//     _connectivity.onConnectivityChanged
//         .listen((List<ConnectivityResult> results) async {
//       // For web and mobile, check actual internet access
//       final hasInternet = await _hasActualInternetAccess();
//       _connectionController.add(hasInternet);
//     });
//   }

//   Stream<bool> get onConnectivityChanged => _connectionController.stream;

//   Future<bool> hasConnection() async {
//     // First check if there's any network connection
//     final results = await _connectivity.checkConnectivity();

//     // If no network connection at all, return false
//     if (results.isEmpty || results.contains(ConnectivityResult.none)) {
//       return false;
//     }

//     // If there is network connection, verify actual internet access
//     return await _hasActualInternetAccess();
//   }

//   Future<bool> _hasActualInternetAccess() async {
//     try {
//       // Try to reach a reliable endpoint with short timeout
//       final response = await http.get(
//         Uri.parse('https://www.google.com/generate_204'),
//         headers: {
//           'Cache-Control': 'no-cache',
//           'Pragma': 'no-cache',
//         },
//       ).timeout(const Duration(seconds: 5));

//       // Check if we got any successful response
//       return response.statusCode == 204 || response.statusCode == 200;
//     } catch (e) {
//       // If we can't reach Google, try a fallback endpoint
//       try {
//         final fallbackResponse = await http
//             .get(
//               Uri.parse('https://clients3.google.com/generate_204'),
//             )
//             .timeout(const Duration(seconds: 3));
//         return fallbackResponse.statusCode == 204 ||
//             fallbackResponse.statusCode == 200;
//       } catch (e) {
//         return false;
//       }
//     }
//   }

//   void dispose() {
//     _connectionController.close();
//   }
// }

// lib/services/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:html' as html; // For web only

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectionController;

  ConnectivityService() {
    _connectionController = StreamController<bool>();
    _initConnectivityMonitoring();
  }

  void _initConnectivityMonitoring() {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasInternet = await hasConnection();
      _connectionController.add(hasInternet);
    });
  }

  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  Future<bool> hasConnection() async {
    // For web platform, use browser's navigator.onLine
    if (isWeb) {
      return _hasWebConnection();
    }

    // For mobile/desktop, do the actual HTTP check
    final results = await _connectivity.checkConnectivity();

    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    return await _hasActualInternetAccess();
  }

  bool get isWeb {
    // Detect web platform
    // ignore: avoid_web_libraries_in_flutter
    return identical(0, 0.0) ? false : true;
  }

  bool _hasWebConnection() {
    try {
      // Use browser's native online detection
      // ignore: undefined_prefixed_name
      return html.window.navigator.onLine ?? true;
    } catch (e) {
      return true; // Default to true if can't detect
    }
  }

  Future<bool> _hasActualInternetAccess() async {
    try {
      // Use a CORS-friendly endpoint that allows cross-origin requests
      final response = await http.get(
        Uri.parse('https://httpbin.org/status/200'),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      // Fallback: Check if we can reach your own backend or a CORS-enabled endpoint
      try {
        // Option 1: Use a service that supports CORS
        final fallbackResponse = await http
            .get(
              Uri.parse('https://api.github.com/zen'),
            )
            .timeout(const Duration(seconds: 3));
        return fallbackResponse.statusCode == 200;
      } catch (e) {
        return false;
      }
    }
  }

  void dispose() {
    _connectionController.close();
  }
}
