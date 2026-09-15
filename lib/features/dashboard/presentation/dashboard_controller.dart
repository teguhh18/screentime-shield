import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../app_lock/data/app_lock_repository.dart';
import '../data/app_usage_repository.dart';
import '../domain/monitored_app_model.dart';
import '../../settings/presentation/permissions_controller.dart';

// ── State ────────────────────────────────────────────────────────────

class DashboardState extends Equatable {
  final List<MonitoredApp> apps;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const DashboardState({
    this.apps = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  int get totalScreenTimeMs =>
      apps.fold(0, (sum, app) => sum + app.usageTimeMs);

  int get monitoredAppsCount => apps.where((a) => a.isMonitored).length;

  List<MonitoredApp> get filteredApps {
    if (searchQuery.isEmpty) return apps;
    return apps
        .where((a) =>
            a.appName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            a.packageName.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  DashboardState copyWith({
    List<MonitoredApp>? apps,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return DashboardState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [apps, isLoading, errorMessage, searchQuery];
}

// ── Notifier ─────────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final AppUsageRepository _usageRepo;
  final AppLockRepository _lockRepo;
  final FlutterSecureStorage _secureStorage;

  static const String _configsStorageKey = 'monitored_app_configs_json';

  DashboardNotifier(
    this._usageRepo,
    this._lockRepo, {
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const DashboardState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Fetch installed apps & current usage from Android OS
    final appsRes = await _usageRepo.getInstalledApps();
    final usageRes = await _usageRepo.getTodayUsageStats();

    final List<dynamic> installedRaw = appsRes.fold((_) => [], (v) => v);
    final List<dynamic> usageRaw = usageRes.fold((_) => [], (v) => v);

    // Build map of usage time
    final usageMap = <String, int>{};
    for (final item in usageRaw) {
      if (item is Map) {
        final pkg = item['packageName'] as String?;
        final time = (item['totalTimeInForeground'] as num?)?.toInt() ?? 0;
        if (pkg != null) usageMap[pkg] = time;
      }
    }

    // 1. Read JSON string from Secure Storage (primary password-like storage)
    String? jsonStr;
    try {
      jsonStr = await _secureStorage.read(key: _configsStorageKey);
    } catch (_) {}

    // 2. Fallback to Hive string box if Secure Storage is empty
    if (jsonStr == null || jsonStr.isEmpty) {
      final hiveRes = await LocalStorageService.read<String>(
        HiveBoxes.settings,
        _configsStorageKey,
      );
      hiveRes.fold((_) {}, (val) {
        if (val != null && val.isNotEmpty) jsonStr = val;
      });
    }

    // Parse JSON configs into map by packageName
    final savedConfigsMap = <String, Map<String, dynamic>>{};
    if (jsonStr != null && jsonStr!.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(jsonStr!);
        for (final item in decodedList) {
          if (item is Map) {
            final casted = Map<String, dynamic>.from(item);
            final pkg = casted['packageName'] as String?;
            if (pkg != null) savedConfigsMap[pkg] = casted;
          }
        }
      } catch (_) {}
    }

    final List<MonitoredApp> parsedApps = [];
    for (final item in installedRaw) {
      if (item is Map) {
        final pkg = item['packageName'] as String? ?? '';
        final name = item['appName'] as String? ?? pkg;
        final icon = item['icon'] as String? ?? '';

        final savedConfig = savedConfigsMap[pkg];
        if (savedConfig != null) {
          parsedApps.add(
            MonitoredApp.fromMap(
              savedConfig,
              appName: name,
              iconBase64: icon,
              usageTimeMs: usageMap[pkg] ?? 0,
            ),
          );
        } else {
          parsedApps.add(
            MonitoredApp(
              packageName: pkg,
              appName: name,
              iconBase64: icon,
              usageTimeMs: usageMap[pkg] ?? 0,
            ),
          );
        }
      }
    }

    // Sort: Monitored apps first, then by usage time descending
    parsedApps.sort((a, b) {
      if (a.isMonitored != b.isMonitored) {
        return a.isMonitored ? -1 : 1;
      }
      return b.usageTimeMs.compareTo(a.usageTimeMs);
    });

    state = state.copyWith(apps: parsedApps, isLoading: false);

    // Sync active settings to native service
    await _lockRepo.startService();
    await _lockRepo.updateMonitoredApps(parsedApps);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Updates full monitoring configuration for a specific package.
  Future<void> configureAppLimit({
    required String packageName,
    required int limitMinutes,
    required String lockMode,
  }) async {
    final updatedApps = state.apps.map((app) {
      if (app.packageName == packageName) {
        return app.copyWith(
          timeLimitMinutes: limitMinutes,
          isMonitored: limitMinutes > 0,
          lockMode: lockMode,
        );
      }
      return app;
    }).toList();

    state = state.copyWith(apps: updatedApps);

    // Save to Secure Storage & Hive
    await _saveConfigsToStorage(updatedApps);

    // Sync to native Android background service
    await _lockRepo.updateMonitoredApps(updatedApps);
  }

  /// Replaces the per-weekday schedule for a package.
  ///
  /// An empty map clears the schedule so every day follows the global limit.
  Future<void> configureWeeklyLimits({
    required String packageName,
    required Map<int, int> weeklyLimits,
  }) async {
    final updatedApps = state.apps.map((app) {
      if (app.packageName == packageName) {
        return app.copyWith(weeklyLimits: weeklyLimits);
      }
      return app;
    }).toList();

    state = state.copyWith(apps: updatedApps);

    await _saveConfigsToStorage(updatedApps);
    await _lockRepo.updateMonitoredApps(updatedApps);
  }

  /// Toggles monitoring on/off quickly.
  Future<void> toggleMonitoring(String packageName, bool isMonitored) async {    final updatedApps = state.apps.map((app) {
      if (app.packageName == packageName) {
        final limit = isMonitored
            ? (app.timeLimitMinutes == 0 ? 30 : app.timeLimitMinutes)
            : 0;
        return app.copyWith(
          isMonitored: isMonitored,
          timeLimitMinutes: limit,
        );
      }
      return app;
    }).toList();

    state = state.copyWith(apps: updatedApps);
    await _saveConfigsToStorage(updatedApps);
    await _lockRepo.updateMonitoredApps(updatedApps);
  }

  /// Encodes monitored apps into JSON string and writes to Secure Storage & Hive.
  Future<void> _saveConfigsToStorage(List<MonitoredApp> apps) async {
    try {
      // isActive (not isMonitored): an app may only have a weekly schedule set,
      // with no global limit.
      final activeOnly = apps.where((a) => a.isActive).toList();
      final configsList = activeOnly.map((a) => a.toMap()).toList();
      final jsonStr = jsonEncode(configsList);

      // Save to FlutterSecureStorage (Encrypted SharedPreferences)
      await _secureStorage.write(key: _configsStorageKey, value: jsonStr);

      // Save to Hive string box
      await LocalStorageService.write(
        HiveBoxes.settings,
        _configsStorageKey,
        jsonStr,
      );
    } catch (_) {}
  }
}

// ── Providers ────────────────────────────────────────────────────────

final dashboardStateProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.watch(appUsageRepoProvider),
    ref.watch(appLockRepoProvider),
  );
});
