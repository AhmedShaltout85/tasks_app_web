
// lib/services/dialog_service.dart (ACTIVE-WITH-WEB-MOBILE)
import 'package:flutter/material.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class ConnectionDialogService {
  static ConnectivityService? _connectivityService;

  static Future<void> showNoInternetDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    // Better mounting check
    if (!context.mounted) return;

    // Ensure dialog is shown after a short delay (helps with web)
    await Future.delayed(Duration.zero);

    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
        content: const Text(
          'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
            },
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () async {
                // Close dialog immediately to prevent issues
                if (Navigator.canPop(dialogContext))
                  Navigator.pop(dialogContext);

                // Wait for dialog to close
                await Future.delayed(const Duration(milliseconds: 100));

                _connectivityService = ConnectivityService.instance;
                final hasConnection =
                    await _connectivityService!.hasConnection();

                if (!hasConnection && context.mounted) {
                  // Still no connection, show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Center(
                        child: Text(
                          'ما زال لا يوجد اتصال بالإنترنت',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Optionally show dialog again
                  if (context.mounted) {
                    await showNoInternetDialog(context, onRetry: onRetry);
                  }
                  return;
                }

                if (context.mounted && onRetry != null) {
                  onRetry();
                }
              },
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
        ],
      ),
    );
  }

  static Future<bool> checkAndHandleConnection(
    BuildContext context, {
    VoidCallback? onConnected,
  }) async {
    if (!context.mounted) return false;

    _connectivityService = ConnectivityService.instance;
    final hasConnection = await _connectivityService!.hasConnection();

    if (!hasConnection && context.mounted) {
      await showNoInternetDialog(
        context,
        onRetry: onConnected,
      );
      return false;
    }

    return hasConnection;
  }
}
