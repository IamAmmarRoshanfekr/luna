import 'package:flutter/material.dart';

import '../../../core/models/vpn_engine.dart';

class EngineTile extends StatelessWidget {
  final VpnEngine engine;
  final EngineStatus status;
  final EngineAdjustments adjustments;
  final VoidCallback onTap;

  const EngineTile({
    super.key,
    required this.engine,
    required this.status,
    required this.adjustments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isConnected = status == EngineStatus.connected;
    final bool isConnecting = status == EngineStatus.connecting;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: engine.gradientColors,
                    ),
                    border: Border.all(
                      color: isConnected
                          ? Colors.greenAccent
                          : Colors.white.withValues(alpha: 0.14),
                      width: isConnected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConnected
                            ? Colors.greenAccent.withValues(alpha: 0.35)
                            : engine.gradientColors.last.withValues(alpha: 0.2),
                        blurRadius: isConnected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isConnecting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(engine.icon, color: Colors.white, size: 30),
                  ),
                ),
                if (isConnected)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0B0F19),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              engine.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isConnected ? Colors.greenAccent : Colors.white,
                fontSize: 12,
                height: 1.15,
                fontWeight: isConnected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'MTU ${adjustments.mtu}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
