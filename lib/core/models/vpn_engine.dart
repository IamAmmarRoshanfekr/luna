import 'package:flutter/material.dart';

enum EngineStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum ProtocolType {
  adaptive,
  wireguard,
  xray,
  lantern,
  warp,
  psiphon,
  tor,
  openvpn,
}

class XrayConfigItem {
  final String id;
  final String label;
  final String uri;

  const XrayConfigItem({
    required this.id,
    required this.label,
    required this.uri,
  });

  XrayConfigItem copyWith({
    String? id,
    String? label,
    String? uri,
  }) {
    return XrayConfigItem(
      id: id ?? this.id,
      label: label ?? this.label,
      uri: uri ?? this.uri,
    );
  }
}

class EngineAdjustments {
  final int mtu;
  final bool bypassLan;
  final bool autoReconnect;
  final String transportMode;
  final String customEndpoint;

  // Xray-specific config management
  final List<XrayConfigItem> configs;
  final String? selectedConfigId;

  // Psiphon-specific controls
  final String egressRegion;
  final bool splitTunnelProxyOnly;

  // WireGuard / WARP / Tor / OpenVPN extras
  final int? persistentKeepalive;
  final String torBridge;
  final String openVpnCipher;

  const EngineAdjustments({
    this.mtu = 1420,
    this.bypassLan = true,
    this.autoReconnect = true,
    this.transportMode = 'Auto',
    this.customEndpoint = '',
    this.configs = const [],
    this.selectedConfigId,
    this.egressRegion = 'Auto',
    this.splitTunnelProxyOnly = false,
    this.persistentKeepalive = 25,
    this.torBridge = 'Snowflake',
    this.openVpnCipher = 'AES-256-GCM',
  });

  int get effectiveKeepalive => persistentKeepalive ?? 25;

  XrayConfigItem? get activeConfig {
    if (configs.isEmpty) return null;
    if (selectedConfigId == null) return configs.first;
    for (final c in configs) {
      if (c.id == selectedConfigId) return c;
    }
    return configs.first;
  }

  EngineAdjustments copyWith({
    int? mtu,
    bool? bypassLan,
    bool? autoReconnect,
    String? transportMode,
    String? customEndpoint,
    List<XrayConfigItem>? configs,
    String? selectedConfigId,
    bool clearSelectedConfig = false,
    String? egressRegion,
    bool? splitTunnelProxyOnly,
    int? persistentKeepalive,
    String? torBridge,
    String? openVpnCipher,
  }) {
    return EngineAdjustments(
      mtu: mtu ?? this.mtu,
      bypassLan: bypassLan ?? this.bypassLan,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      transportMode: transportMode ?? this.transportMode,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      configs: configs ?? this.configs,
      selectedConfigId:
          clearSelectedConfig ? null : (selectedConfigId ?? this.selectedConfigId),
      egressRegion: egressRegion ?? this.egressRegion,
      splitTunnelProxyOnly: splitTunnelProxyOnly ?? this.splitTunnelProxyOnly,
      persistentKeepalive: persistentKeepalive ?? this.persistentKeepalive,
      torBridge: torBridge ?? this.torBridge,
      openVpnCipher: openVpnCipher ?? this.openVpnCipher,
    );
  }
}

class VpnEngine {
  final String id;
  final String name;
  final String subtitle;
  final ProtocolType protocol;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> transportOptions;

  const VpnEngine({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.protocol,
    required this.icon,
    required this.gradientColors,
    this.transportOptions = const ['Auto', 'Stealth', 'Fast'],
  });
}