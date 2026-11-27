import 'package:flutter/material.dart';
import '../../core/models/vpn_engine.dart';

class EngineDetailScreen extends StatefulWidget {
  final VpnEngine engine;
  final EngineStatus status;
  final EngineAdjustments adjustments;
  final ValueChanged<EngineAdjustments> onAdjustmentsChanged;
  final VoidCallback onToggleConnect;

  const EngineDetailScreen({
    super.key,
    required this.engine,
    required this.status,
    required this.adjustments,
    required this.onAdjustmentsChanged,
    required this.onToggleConnect,
  });

  @override
  State<EngineDetailScreen> createState() => _EngineDetailScreenState();
}

class _EngineDetailScreenState extends State<EngineDetailScreen> {
  static const List<String> _regions = ['Auto', 'DE', 'NL', 'US', 'GB', 'JP'];
  static const List<String> _bridges = ['Snowflake', 'obfs4', 'WebTunnel'];
  static const List<String> _ciphers = [
    'AES-256-GCM',
    'CHACHA20-POLY1305',
    'AES-128-GCM',
  ];

  late final TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    _endpointController =
        TextEditingController(text: widget.adjustments.customEndpoint);
  }

  @override
  void didUpdateWidget(covariant EngineDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adjustments.customEndpoint != _endpointController.text &&
        widget.adjustments.customEndpoint != oldWidget.adjustments.customEndpoint) {
      _endpointController.text = widget.adjustments.customEndpoint;
    }
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  void _updateAdjustments(EngineAdjustments next) {
    widget.onAdjustmentsChanged(next);
  }

  Future<void> _showAddConfigDialog() async {
    final labelCtrl = TextEditingController();
    final uriCtrl = TextEditingController();

    final created = await showDialog<XrayConfigItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        title: const Text('Add Xray Config'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Config Name',
                hintText: 'e.g. FR-Reality-Main',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: uriCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Share Link / Config URI',
                hintText: 'vless://... or vmess://... or trojan://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final uri = uriCtrl.text.trim();
              if (uri.isEmpty) return;
              final rawLabel = labelCtrl.text.trim();
              String inferred = 'Config ${widget.adjustments.configs.length + 1}';
              if (rawLabel.isNotEmpty) {
                inferred = rawLabel;
              } else if (uri.contains('#')) {
                try {
                  inferred = Uri.decodeComponent(uri.split('#').last);
                } catch (_) {
                  inferred = uri.split('#').last;
                }
              }
              Navigator.pop(
                ctx,
                XrayConfigItem(
                  id: 'cfg_${DateTime.now().microsecondsSinceEpoch}',
                  label: inferred,
                  uri: uri,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      labelCtrl.dispose();
      uriCtrl.dispose();
    });

    if (created == null || !mounted) return;
    final updatedConfigs = [...widget.adjustments.configs, created];
    _updateAdjustments(
      widget.adjustments.copyWith(
        configs: updatedConfigs,
        selectedConfigId: created.id,
      ),
    );
  }

  void _deleteConfig(XrayConfigItem item) {
    final remaining =
        widget.adjustments.configs.where((c) => c.id != item.id).toList();
    final nextSelected = widget.adjustments.selectedConfigId == item.id
        ? (remaining.isNotEmpty ? remaining.first.id : null)
        : widget.adjustments.selectedConfigId;
    _updateAdjustments(
      widget.adjustments.copyWith(
        configs: remaining,
        selectedConfigId: nextSelected,
        clearSelectedConfig: nextSelected == null,
      ),
    );
  }

  Widget _buildHeaderCard(bool isConnected, bool isConnecting) {
    final activeXray = widget.engine.protocol == ProtocolType.xray
        ? widget.adjustments.activeConfig
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.engine.gradientColors,
                  ),
                ),
                child: Icon(widget.engine.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.engine.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeXray != null
                          ? 'Selected: ${activeXray.label}'
                          : widget.engine.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? Colors.greenAccent
                                : isConnecting
                                    ? Colors.amberAccent
                                    : Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected
                              ? 'Connected'
                              : isConnecting
                                  ? 'Connecting...'
                                  : 'Disconnected',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isConnected
                                ? Colors.greenAccent
                                : isConnecting
                                    ? Colors.amberAccent
                                    : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isConnected
                    ? Colors.redAccent.withValues(alpha: 0.9)
                    : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isConnecting ? null : widget.onToggleConnect,
              icon: isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isConnected
                          ? Icons.power_settings_new_rounded
                          : Icons.bolt_rounded,
                    ),
              label: Text(
                isConnected
                    ? 'Disconnect ${widget.engine.name}'
                    : isConnecting
                        ? 'Establishing Tunnel...'
                        : 'Connect ${widget.engine.name}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolSection() {
    final adj = widget.adjustments;

    switch (widget.engine.protocol) {
      case ProtocolType.xray:
        final selectedId = adj.activeConfig?.id;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Xray Configs',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _showAddConfigDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Config'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (adj.configs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'No configs yet. Tap "Add Config" to paste a VLESS, VMess, or Trojan link.',
                    style: TextStyle(fontSize: 12.5, color: Colors.white60),
                  ),
                )
              else
                ...adj.configs.map((cfg) {
                  final isSelected = cfg.id == selectedId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _updateAdjustments(
                        adj.copyWith(selectedConfigId: cfg.id),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cfg.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cfg.uri,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete config',
                              onPressed: () => _deleteConfig(cfg),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );

      case ProtocolType.psiphon:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Psiphon Features',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    _regions.contains(adj.egressRegion) ? adj.egressRegion : 'Auto',
                dropdownColor: const Color(0xFF1A2236),
                decoration: InputDecoration(
                  labelText: 'Egress Country / Region',
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    _updateAdjustments(adj.copyWith(egressRegion: val));
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Local SOCKS / HTTP Proxy Only',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Expose local proxy instead of full-device VPN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                value: adj.splitTunnelProxyOnly,
                onChanged: (val) =>
                    _updateAdjustments(adj.copyWith(splitTunnelProxyOnly: val)),
              ),
            ],
          ),
        );

      case ProtocolType.tor:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tor Bridge & Circuit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    _bridges.contains(adj.torBridge) ? adj.torBridge : 'Snowflake',
                dropdownColor: const Color(0xFF1A2236),
                decoration: InputDecoration(
                  labelText: 'Pluggable Transport',
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _bridges
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    _updateAdjustments(adj.copyWith(torBridge: val));
                  }
                },
              ),
            ],
          ),
        );

      case ProtocolType.openvpn:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OpenVPN Cipher',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ciphers.contains(adj.openVpnCipher)
                    ? adj.openVpnCipher
                    : 'AES-256-GCM',
                dropdownColor: const Color(0xFF1A2236),
                decoration: InputDecoration(
                  labelText: 'Data Channel Cipher',
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _ciphers
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    _updateAdjustments(adj.copyWith(openVpnCipher: val));
                  }
                },
              ),
            ],
          ),
        );

      case ProtocolType.wireguard:
      case ProtocolType.warp:
      case ProtocolType.lantern:
      case ProtocolType.adaptive:
        final keepalive = adj.effectiveKeepalive.clamp(5, 120);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Keepalive Interval',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${keepalive}s',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                ],
              ),
              Slider(
                min: 5,
                max: 120,
                divisions: 23,
                value: keepalive.toDouble(),
                onChanged: (v) => _updateAdjustments(
                  adj.copyWith(persistentKeepalive: v.round()),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adj = widget.adjustments;
    final bool isConnected = widget.status == EngineStatus.connected;
    final bool isConnecting = widget.status == EngineStatus.connecting;
    final clampedMtu = adj.mtu.clamp(1200, 1500);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.engine.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeaderCard(isConnected, isConnecting),
            const SizedBox(height: 20),
            _buildProtocolSection(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'TUNNEL ADJUSTMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport / Obfuscation Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: widget.engine.transportOptions
                            .contains(adj.transportMode)
                        ? adj.transportMode
                        : widget.engine.transportOptions.first,
                    dropdownColor: const Color(0xFF1A2236),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0B0F19),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.engine.transportOptions
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateAdjustments(adj.copyWith(transportMode: value));
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Packet MTU Size',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$clampedMtu',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 1200,
                    max: 1500,
                    divisions: 30,
                    value: clampedMtu.toDouble(),
                    onChanged: (val) =>
                        _updateAdjustments(adj.copyWith(mtu: val.round())),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bypass Local Network (LAN)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    value: adj.bypassLan,
                    onChanged: (val) =>
                        _updateAdjustments(adj.copyWith(bypassLan: val)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto-Reconnect on Drop',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    value: adj.autoReconnect,
                    onChanged: (val) =>
                        _updateAdjustments(adj.copyWith(autoReconnect: val)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _endpointController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Override Endpoint / Notes (Optional)',
                      filled: true,
                      fillColor: const Color(0xFF0B0F19),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => _updateAdjustments(
                      adj.copyWith(customEndpoint: val.trim()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}