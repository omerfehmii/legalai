import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bağlantı durumunu izlemek için enum
enum ConnectionStatus {
  online,
  offline
}

/// Bağlantı durumunu yöneten servis
class ConnectivityService extends StateNotifier<ConnectionStatus> {
  StreamSubscription<ConnectivityResult>? _subscription;
  
  ConnectivityService() : super(ConnectionStatus.online) {
    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        state = ConnectionStatus.offline;
      } else {
        state = ConnectionStatus.online;
      }
    });
    
    // Başlangıçta bağlantı durumunu kontrol et
    checkConnectivity();
  }
  
  /// Mevcut bağlantı durumunu kontrol et
  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      state = ConnectionStatus.offline;
    } else {
      state = ConnectionStatus.online;
    }
  }
  
  /// Bağlantı durumu dinleyicisini kapat
  void dispose() {
    _subscription?.cancel();
  }
  
  /// Çevrimdışı mod aktif mi?
  bool get isOffline => state == ConnectionStatus.offline;
  
  /// Çevrimiçi mod aktif mi?
  bool get isOnline => state == ConnectionStatus.online;
}

/// Bağlantı durumu provider'ı
final connectivityProvider = StateNotifierProvider<ConnectivityService, ConnectionStatus>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Çevrimdışı bildirimi gösteren widget
class OfflineNotification extends ConsumerWidget {
  final Widget child;
  
  const OfflineNotification({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectivityProvider);
    
    return Stack(
      children: [
        child,
        if (connectionStatus == ConnectionStatus.offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Çevrimdışı mod - Bazı özellikler sınırlı olabilir',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
} 