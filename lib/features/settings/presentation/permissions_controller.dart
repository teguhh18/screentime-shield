import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_lock/data/app_lock_repository.dart';
import '../../dashboard/data/app_usage_repository.dart';
import '../data/device_admin_repository.dart';

// ── State ────────────────────────────────────────────────────────────

class PermissionsState extends Equatable {
  final bool isUsageStatsGranted;
  final bool isOverlayGranted;
  final bool isDeviceAdminGranted;
  final bool isLoading;

  const PermissionsState({
    this.isUsageStatsGranted = false,
    this.isOverlayGranted = false,
    this.isDeviceAdminGranted = false,
    this.isLoading = false,
  });

  bool get areAllGranted =>
      isUsageStatsGranted && isOverlayGranted && isDeviceAdminGranted;

  PermissionsState copyWith({
    bool? isUsageStatsGranted,
    bool? isOverlayGranted,
    bool? isDeviceAdminGranted,
    bool? isLoading,
  }) {
    return PermissionsState(
      isUsageStatsGranted: isUsageStatsGranted ?? this.isUsageStatsGranted,
      isOverlayGranted: isOverlayGranted ?? this.isOverlayGranted,
      isDeviceAdminGranted: isDeviceAdminGranted ?? this.isDeviceAdminGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        isUsageStatsGranted,
        isOverlayGranted,
        isDeviceAdminGranted,
        isLoading,
      ];
}

// ── Notifier ─────────────────────────────────────────────────────────

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final AppUsageRepository _usageRepo;
  final AppLockRepository _lockRepo;
  final DeviceAdminRepository _adminRepo;

  PermissionsNotifier(
    this._usageRepo,
    this._lockRepo,
    this._adminRepo,
  ) : super(const PermissionsState()) {
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    state = state.copyWith(isLoading: true);

    final usageRes = await _usageRepo.checkUsagePermission();
    final overlayRes = await _lockRepo.checkOverlayPermission();
    final adminRes = await _adminRepo.checkAdminStatus();

    state = PermissionsState(
      isUsageStatsGranted: usageRes.fold((_) => false, (v) => v),
      isOverlayGranted: overlayRes.fold((_) => false, (v) => v),
      isDeviceAdminGranted: adminRes.fold((_) => false, (v) => v),
      isLoading: false,
    );
  }

  Future<void> requestUsagePermission() async {
    await _usageRepo.requestUsagePermission();
  }

  Future<void> requestOverlayPermission() async {
    await _lockRepo.requestOverlayPermission();
  }

  Future<void> requestDeviceAdmin() async {
    await _adminRepo.requestAdmin();
  }

  Future<bool> removeDeviceAdmin() async {
    final res = await _adminRepo.removeAdmin();
    await checkAllPermissions();
    return res.fold((_) => false, (v) => v);
  }
}

// ── Providers ────────────────────────────────────────────────────────

final appUsageRepoProvider = Provider<AppUsageRepository>((ref) {
  return AppUsageRepository();
});

final appLockRepoProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepository();
});

final deviceAdminRepoProvider = Provider<DeviceAdminRepository>((ref) {
  return DeviceAdminRepository();
});

final permissionsStateProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier(
    ref.watch(appUsageRepoProvider),
    ref.watch(appLockRepoProvider),
    ref.watch(deviceAdminRepoProvider),
  );
});
