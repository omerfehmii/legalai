import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:legalai/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Bekleyen senkronizasyon işleminin durumu
enum SyncStatus {
  pending,   // Beklemede
  syncing,   // Senkronize ediliyor
  completed, // Tamamlandı
  failed     // Başarısız
}

/// Bekleyen senkronizasyon işlemi
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  SyncStatus status;
  String? errorMessage;

  PendingOperation({
    required this.type,
    required this.data,
    this.status = SyncStatus.pending,
    this.errorMessage,
  }) : 
    id = const Uuid().v4(),
    createdAt = DateTime.now();

  // Hive için dönüşüm metodları
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'status': status.toString(),
    'errorMessage': errorMessage,
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      type: json['type'],
      data: json['data'],
      status: _syncStatusFromString(json['status']),
      errorMessage: json['errorMessage'],
    );
  }

  static SyncStatus _syncStatusFromString(String status) {
    switch (status) {
      case 'SyncStatus.pending': return SyncStatus.pending;
      case 'SyncStatus.syncing': return SyncStatus.syncing;
      case 'SyncStatus.completed': return SyncStatus.completed;
      case 'SyncStatus.failed': return SyncStatus.failed;
      default: return SyncStatus.pending;
    }
  }
}

/// Çevrimdışı işlemleri yöneten servis
class OfflineSyncService extends ChangeNotifier {
  static const String _pendingBoxName = 'pending_operations';
  Box<String>? _pendingBox;
  final ConnectivityService _connectivityService;
  bool _isSyncing = false;

  OfflineSyncService(this._connectivityService) {
    _init();
  }

  Future<void> _init() async {
    _pendingBox = await Hive.openBox<String>(_pendingBoxName);
    
    // Not: ConnectivityService bir StateNotifier olduğu için addListener yok
    // Bağlantı durumu değişimlerini kayan dalga verileri (stream) üzerinden takip ederiz
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Bağlantı geri geldiğinde senkronizasyonu başlat
        syncPendingOperations();
      }
    });
  }

  /// Bekleyen tüm işlemleri listele
  List<PendingOperation> getPendingOperations() {
    if (_pendingBox == null) return [];
    
    return _pendingBox!.values
        .map((json) => PendingOperation.fromJson(jsonDecode(json)))
        .where((op) => op.status == SyncStatus.pending || op.status == SyncStatus.failed)
        .toList();
  }

  /// Yeni bir bekleyen işlem ekle
  Future<void> addPendingOperation(String type, Map<String, dynamic> data) async {
    if (_pendingBox == null) return;
    
    final operation = PendingOperation(
      type: type,
      data: data,
    );
    
    await _pendingBox!.put(operation.id, jsonEncode(operation.toJson()));
    notifyListeners();
    
    // Çevrimiçiyse hemen senkronize et
    if (_connectivityService.isOnline) {
      syncPendingOperations();
    }
  }

  /// Bekleyen işlemleri senkronize et
  Future<void> syncPendingOperations() async {
    if (_isSyncing || _pendingBox == null || !_connectivityService.isOnline) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      final operations = getPendingOperations();
      
      for (final operation in operations) {
        try {
          // İşlem durumunu güncelle
          operation.status = SyncStatus.syncing;
          await _updateOperation(operation);
          
          // İşlem tipine göre ilgili senkronizasyon kodu çalıştırılacak
          bool success = await _processPendingOperation(operation);
          
          if (success) {
            operation.status = SyncStatus.completed;
          } else {
            operation.status = SyncStatus.failed;
            operation.errorMessage = 'İşlem senkronize edilemedi';
          }
        } catch (e) {
          operation.status = SyncStatus.failed;
          operation.errorMessage = e.toString();
        }
        
        // İşlem durumunu güncelle
        await _updateOperation(operation);
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Bekleyen işlemi işle
  Future<bool> _processPendingOperation(PendingOperation operation) async {
    // İşlem tipine göre yapılacak işlem
    switch (operation.type) {
      case 'create_document':
        // Document oluşturma işlemi
        // TODO: API'ye belge oluşturma isteği gönder
        return await Future.delayed(const Duration(seconds: 1), () => true);
      
      case 'update_document':
        // Document güncelleme işlemi  
        // TODO: API'ye belge güncelleme isteği gönder
        return await Future.delayed(const Duration(seconds: 1), () => true);
        
      case 'delete_document':
        // Document silme işlemi
        // TODO: API'ye belge silme isteği gönder
        return await Future.delayed(const Duration(seconds: 1), () => true);
        
      default:
        // Bilinmeyen işlem tipi
        return false;
    }
  }

  /// İşlem durumunu güncelle
  Future<void> _updateOperation(PendingOperation operation) async {
    if (_pendingBox == null) return;
    await _pendingBox!.put(operation.id, jsonEncode(operation.toJson()));
    notifyListeners();
  }

  /// Tamamlanan işlemleri temizle
  Future<void> clearCompletedOperations() async {
    if (_pendingBox == null) return;
    
    final operations = _pendingBox!.values
        .map((json) => PendingOperation.fromJson(jsonDecode(json)))
        .where((op) => op.status == SyncStatus.completed)
        .toList();
    
    for (final operation in operations) {
      await _pendingBox!.delete(operation.id);
    }
    
    notifyListeners();
  }
}

/// Offline senkronizasyon servisi sağlayıcısı
final offlineSyncServiceProvider = ChangeNotifierProvider<OfflineSyncService>((ref) {
  final connectivityService = ref.watch(connectivityProvider.notifier);
  return OfflineSyncService(connectivityService);
}); 