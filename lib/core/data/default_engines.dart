import 'package:flutter/material.dart';

import '../models/vpn_engine.dart';

const List<VpnEngine> defaultVpnEngines = [
  VpnEngine(
    id: 'luna_auto',
    name: 'Luna Smart',
    subtitle: 'Adaptive routing',
    protocol: ProtocolType.adaptive,
    icon: Icons.auto_awesome_rounded,
    gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    transportOptions: ['Smart Probe', 'Lowest Latency', 'High Censorship'],
  ),
  VpnEngine(
    id: 'wireguard',
    name: 'WireGuard',
    subtitle: 'UDP kernel tunnel',
    protocol: ProtocolType.wireguard,
    icon: Icons.shield_rounded,
    gradientColors: [Color(0xFF991B1B), Color(0xFFDC2626)],
    transportOptions: ['Standard UDP', 'Amnezia H1-H4', 'Keepalive 25s'],
  ),
  VpnEngine(
    id: 'xray',
    name: 'Xray Core',
    subtitle: 'VLESS / Reality',
    protocol: ProtocolType.xray,
    icon: Icons.bolt_rounded,
    gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    transportOptions: ['VLESS + Reality', 'XHTTP', 'gRPC'],
  ),
  VpnEngine(
    id: 'lantern',
    name: 'Lantern',
    subtitle: 'Censorship bypass',
    protocol: ProtocolType.lantern,
    icon: Icons.lightbulb_rounded,
    gradientColors: [Color(0xFFD97706), Color(0xFFFBBF24)],
    transportOptions: ['Auto Relay', 'Fronted TLS', 'P2P Assist'],
  ),
  VpnEngine(
    id: 'warp',
    name: 'WARP',
    subtitle: 'Cloudflare tunnel',
    protocol: ProtocolType.warp,
    icon: Icons.cloud_sync_rounded,
    gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
    transportOptions: ['MASQUE', 'WireGuard+', 'Zero Trust'],
  ),
  VpnEngine(
    id: 'psiphon',
    name: 'Psiphon',
    subtitle: 'SSH / Obfuscated',
    protocol: ProtocolType.psiphon,
    icon: Icons.vpn_lock_rounded,
    gradientColors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
    transportOptions: ['OSSH', 'SSH + TLS', 'Meek'],
  ),
  VpnEngine(
    id: 'tor',
    name: 'Tor Network',
    subtitle: 'Onion multi-hop',
    protocol: ProtocolType.tor,
    icon: Icons.hub_rounded,
    gradientColors: [Color(0xFF581C87), Color(0xFF9333EA)],
    transportOptions: ['Direct', 'Snowflake', 'obfs4'],
  ),
  VpnEngine(
    id: 'openvpn',
    name: 'OpenVPN',
    subtitle: 'TLS session tunnel',
    protocol: ProtocolType.openvpn,
    icon: Icons.lock_outline_rounded,
    gradientColors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    transportOptions: ['UDP', 'TCP 443', 'XOR Patch'],
  ),
];

Map<String, EngineAdjustments> createInitialAdjustments() {
  return {
    for (final engine in defaultVpnEngines)
      engine.id: engine.protocol == ProtocolType.xray
          ? const EngineAdjustments(
              transportMode: 'VLESS + Reality',
              selectedConfigId: 'cfg_1',
              configs: [
                XrayConfigItem(
                  id: 'cfg_1',
                  label: 'DE-Reality-01',
                  uri: 'vless://uuid@de1.example.com:443?security=reality&sni=www.cloudflare.com#DE-Reality-01',
                ),
                XrayConfigItem(
                  id: 'cfg_2',
                  label: 'NL-XHTTP-Edge',
                  uri: 'vless://uuid@nl2.example.com:8443?type=xhttp&security=tls#NL-XHTTP-Edge',
                ),
              ],
            )
          : EngineAdjustments(transportMode: engine.transportOptions.first),
  };
}
