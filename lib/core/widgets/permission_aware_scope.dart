import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/permissions_controller.dart';

/// Re-runs [PermissionsNotifier.checkAllPermissions] every time the host
/// route resumes (e.g. user returns from native Settings after granting a
/// permission). Without this the UI kept stale `isGranted = false` until a
/// full app restart.
class PermissionAwareScope extends ConsumerStatefulWidget {
  final Widget child;

  const PermissionAwareScope({super.key, required this.child});

  @override
  ConsumerState<PermissionAwareScope> createState() =>
      _PermissionAwareScopeState();
}

class _PermissionAwareScopeState extends ConsumerState<PermissionAwareScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsStateProvider.notifier).checkAllPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsStateProvider.notifier).checkAllPermissions();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}