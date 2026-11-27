import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/data/default_engines.dart';
import 'core/models/vpn_engine.dart';
import 'features/engine_detail/engine_detail_screen.dart';
import 'features/home/widgets/engine_tile.dart';
import 'features/settings/app_settings_screen.dart';

void main() {
  runApp(const LunaVpnApp());
}

class LunaVpnApp extends StatelessWidget {
  const LunaVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna Multi-VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF131929),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int> _stateVersion = ValueNotifier<int>(0);
  String? _activeEngineId;
  String? _lastUsedEngineId;
  EngineStatus _status = EngineStatus.disconnected;

  Map<String, EngineAdjustments> _adjustmentsByEngine =
      createInitialAdjustments();

  // Tracks usage count per engine so the floating dock surfaces top VPNs
  final Map<String, int> _usageCounts = {
    'luna_auto': 3,
    'wireguard': 2,
    'xray': 1,
  };

  @override
  void dispose() {
    _stateVersion.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    if (!mounted) return;
    setState(() {});
    _stateVersion.value++;
  }

  void _recordUsage(String engineId) {
    _usageCounts[engineId] = (_usageCounts[engineId] ?? 0) + 1;
  }

  void _resetAllAdjustments() {
    _adjustmentsByEngine = createInitialAdjustments();
    _notifyChanged();
  }

  Future<void> _toggleEngineConnection(VpnEngine engine) async {
    _lastUsedEngineId = engine.id;
    _recordUsage(engine.id);

    if (_activeEngineId == engine.id && _status == EngineStatus.connected) {
      _status = EngineStatus.disconnected;
      _activeEngineId = null;
      _notifyChanged();
      return;
    }

    _activeEngineId = engine.id;
    _status = EngineStatus.connecting;
    _notifyChanged();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _activeEngineId != engine.id) return;

    _status = EngineStatus.connected;
    _notifyChanged();
  }

  void _openEnginePage(VpnEngine engine) {
    _lastUsedEngineId ??= engine.id;
    _recordUsage(engine.id);
    _notifyChanged();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EngineDetailHost(
          versionNotifier: _stateVersion,
          engine: engine,
          statusBuilder: () => _activeEngineId == engine.id
              ? _status
              : EngineStatus.disconnected,
          adjustmentsBuilder: () =>
              _adjustmentsByEngine[engine.id] ?? const EngineAdjustments(),
          onAdjustmentsChanged: (updated) {
            _adjustmentsByEngine = {
              ..._adjustmentsByEngine,
              engine.id: updated,
            };
            _notifyChanged();
          },
          onToggleConnect: () => _toggleEngineConnection(engine),
        ),
      ),
    );
  }

  void _openSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AppSettingsScreen(onResetAllAdjustments: _resetAllAdjustments),
      ),
    );
  }

  VpnEngine get _latestEngine {
    final targetId = _activeEngineId ?? _lastUsedEngineId;
    if (targetId == null) return defaultVpnEngines.first;
    return defaultVpnEngines.firstWhere(
      (e) => e.id == targetId,
      orElse: () => defaultVpnEngines.first,
    );
  }

  List<VpnEngine> get _frequentEngines {
    final sorted = [...defaultVpnEngines];
    sorted.sort((a, b) {
      final countA = _usageCounts[a.id] ?? 0;
      final countB = _usageCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final latestEngine = _latestEngine;
    final latestAdj =
        _adjustmentsByEngine[latestEngine.id] ?? const EngineAdjustments();
    final bool isLatestActive = _activeEngineId == latestEngine.id;
    final bool isConnected =
        isLatestActive && _status == EngineStatus.connected;
    final bool isConnecting =
        isLatestActive && _status == EngineStatus.connecting;
    final frequentEngines = _frequentEngines;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Home Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // Top Bar: App Icon (Moon) + App Name Only
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Luna',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Latest VPN Used Card
                  InkWell(
                    onTap: () => _openEnginePage(latestEngine),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131929),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isConnected
                              ? Colors.greenAccent.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: latestEngine.gradientColors,
                              ),
                            ),
                            child: Icon(
                              latestEngine.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Used • ${latestEngine.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isConnected
                                      ? 'Connected • ${latestAdj.transportMode} • MTU ${latestAdj.mtu}'
                                      : isConnecting
                                      ? 'Connecting • ${latestAdj.transportMode}'
                                      : 'Disconnected • ${latestAdj.transportMode} • MTU ${latestAdj.mtu}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isConnected
                                        ? Colors.greenAccent
                                        : Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: isConnected ? 'Disconnect' : 'Connect',
                            onPressed: isConnecting
                                ? null
                                : () => _toggleEngineConnection(latestEngine),
                            icon: isConnecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isConnected
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // VPN Launcher Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: defaultVpnEngines.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 112,
                          ),
                      itemBuilder: (context, index) {
                        final engine = defaultVpnEngines[index];
                        final tileStatus = _activeEngineId == engine.id
                            ? _status
                            : EngineStatus.disconnected;
                        final tileAdj =
                            _adjustmentsByEngine[engine.id] ??
                            const EngineAdjustments();

                        return EngineTile(
                          engine: engine,
                          status: tileStatus,
                          adjustments: tileAdj,
                          onTap: () => _openEnginePage(engine),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Floating Glassified Dock (Frequently Used VPNs + Settings)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E31).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top 3 Frequently Used VPNs
                        ...frequentEngines.map((engine) {
                          final isEngineConnected =
                              _activeEngineId == engine.id &&
                              _status == EngineStatus.connected;

                          return _GlassDockItem(
                            tooltip: '${engine.name} (Frequent)',
                            gradientColors: engine.gradientColors,
                            icon: engine.icon,
                            isActive: isEngineConnected,
                            onTap: () => _openEnginePage(engine),
                          );
                        }),

                        // Subtle Vertical Divider
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),

                        // Settings Icon
                        _GlassDockItem(
                          tooltip: 'Settings',
                          gradientColors: const [
                            Color(0xFF263147),
                            Color(0xFF1B2336),
                          ],
                          icon: Icons.settings_rounded,
                          isActive: false,
                          onTap: _openSettingsPage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDockItem extends StatelessWidget {
  final String tooltip;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _GlassDockItem({
    required this.tooltip,
    required this.gradientColors,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                border: Border.all(
                  color: isActive
                      ? Colors.greenAccent
                      : Colors.white.withValues(alpha: 0.16),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            if (isActive)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF131929),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EngineDetailHost extends StatelessWidget {
  final ValueNotifier<int> versionNotifier;
  final VpnEngine engine;
  final EngineStatus Function() statusBuilder;
  final EngineAdjustments Function() adjustmentsBuilder;
  final ValueChanged<EngineAdjustments> onAdjustmentsChanged;
  final VoidCallback onToggleConnect;

  const _EngineDetailHost({
    required this.versionNotifier,
    required this.engine,
    required this.statusBuilder,
    required this.adjustmentsBuilder,
    required this.onAdjustmentsChanged,
    required this.onToggleConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: versionNotifier,
      builder: (context, _, _) {
        return EngineDetailScreen(
          engine: engine,
          status: statusBuilder(),
          adjustments: adjustmentsBuilder(),
          onAdjustmentsChanged: onAdjustmentsChanged,
          onToggleConnect: onToggleConnect,
        );
      },
    );
  }
}
