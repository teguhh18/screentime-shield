import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';

// ── State ──────────────────────────────────────────────────────────────

class HomeShellState extends Equatable {
  final int index;
  const HomeShellState({this.index = 0});

  HomeShellState copyWith({int? index}) => HomeShellState(index: index ?? this.index);

  @override
  List<Object?> get props => [index];
}

class HomeShellNotifier extends StateNotifier<HomeShellState> {
  HomeShellNotifier() : super(const HomeShellState());

  void setIndex(int index) {
    if (state.index == index) return;
    state = state.copyWith(index: index);
  }
}

final homeShellStateProvider =
    StateNotifierProvider<HomeShellNotifier, HomeShellState>(
  (ref) => HomeShellNotifier(),
);

// ── Shell ──────────────────────────────────────────────────────────────

/// Root shell after login. Hosts the bottom navigation bar that switches
/// between the Dashboard (Home) and Settings tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = <Widget>[
    DashboardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeShellStateProvider).index;
    final notifier = ref.read(homeShellStateProvider.notifier);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: notifier.setIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}