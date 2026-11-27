import 'package:flutter/material.dart';

class AppSettingsScreen extends StatefulWidget {
  final VoidCallback onResetAllAdjustments;

  const AppSettingsScreen({super.key, required this.onResetAllAdjustments});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _killSwitch = true;
  bool _blockIpv6 = false;
  bool _connectOnStart = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            tileColor: const Color(0xFF131929),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Global Kill Switch'),
            subtitle: const Text('Block traffic if active VPN tunnel drops'),
            value: _killSwitch,
            onChanged: (val) => setState(() => _killSwitch = val),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            tileColor: const Color(0xFF131929),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Disable IPv6 Leak'),
            subtitle: const Text('Route IPv6 through tunnel or drop'),
            value: _blockIpv6,
            onChanged: (val) => setState(() => _blockIpv6 = val),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            tileColor: const Color(0xFF131929),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Connect Last Engine on Launch'),
            value: _connectOnStart,
            onChanged: (val) => setState(() => _connectOnStart = val),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              widget.onResetAllAdjustments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset all VPN engine adjustments'),
                ),
              );
            },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset All Engine Adjustments'),
          ),
        ],
      ),
    );
  }
}
