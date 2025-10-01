import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/connectivity_service.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const NetworkErrorWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor ?? Colors.grey[50],
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon ?? Icons.signal_wifi_off,
                  size: screenWidth * 0.12,
                  color: Colors.red,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Title
              Text(
                title ?? 'No Internet Connection',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? theme.textTheme.headlineSmall?.color,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.02),

              // Message
              Text(
                message ??
                    'Please check your network connection and try again.',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: textColor?.withOpacity(0.7) ??
                      theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.04),

              // Connection Status
              Obx(() {
                final connectivityService = ConnectivityService.to;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: connectivityService.isConnected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: connectivityService.isConnected
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connectivityService.isConnected
                            ? Icons.wifi
                            : Icons.wifi_off,
                        size: screenWidth * 0.04,
                        color: connectivityService.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        connectivityService.isConnected
                            ? 'Connected (${connectivityService.getConnectionTypeString()})'
                            : 'Disconnected',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: connectivityService.isConnected
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: screenHeight * 0.04),

              // Retry Button
              if (showRetryButton) ...[
                ElevatedButton.icon(
                  onPressed: onRetry ??
                      () {
                        ConnectivityService.to.checkConnectivity();
                      },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Settings Button
                TextButton.icon(
                  onPressed: () {
                    // Open device settings
                    Get.snackbar(
                      'Settings',
                      'Please check your device network settings',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Check Settings'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactNetworkErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const CompactNetworkErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.signal_wifi_off,
                color: Colors.red,
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  message ?? 'Network connection error. Please connect.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (showRetryButton) ...[
            SizedBox(height: screenWidth * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRetry ??
                      () {
                        ConnectivityService.to.checkConnectivity();
                      },
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
