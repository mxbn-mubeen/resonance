import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Addresses a real, well-documented Android fragmentation problem: some
/// manufacturers (Honor, Huawei, Xiaomi, Oppo, Vivo, Samsung) apply
/// additional, much more aggressive background-process killing on top of
/// stock Android's Doze mode - well beyond what standard "battery
/// optimization" exemption covers. This is why background metadata fetch
/// can work perfectly on one device (e.g. OnePlus, closer to stock
/// Android) and get silently stuck/killed on another (e.g. Honor's
/// MagicOS) with the exact same app code - it's an OS-level restriction,
/// not something purely fixable from inside the app. The best available
/// mitigation is: (1) request the standard exemption, which helps on most
/// devices, and (2) point the user at their specific manufacturer's
/// additional manual whitelist setting, since there's no programmatic way
/// to bypass those OEM-specific restrictions from Flutter/Android app code.
class SettingsBackgroundReliabilitySection extends StatefulWidget {
  const SettingsBackgroundReliabilitySection({super.key});

  @override
  State<SettingsBackgroundReliabilitySection> createState() => _SettingsBackgroundReliabilitySectionState();
}

class _SettingsBackgroundReliabilitySectionState extends State<SettingsBackgroundReliabilitySection> {
  bool? _isExempted;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) setState(() => _isExempted = status.isGranted);
  }

  Future<void> _requestExemption() async {
    final result = await Permission.ignoreBatteryOptimizations.request();
    if (mounted) setState(() => _isExempted = result.isGranted);
    if (mounted && !result.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not granted. Some devices require enabling this manually in system Settings -> '
            'Battery -> find Resonance -> "Unrestricted" or "Don\'t optimize".',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Background Fetch Reliability', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'If background metadata fetch works fine on one phone but stalls or resets when '
            'you close the app on another, this is almost always the manufacturer\'s own battery '
            'manager, not a bug in the fetch itself - some brands are far more aggressive than '
            'stock Android about killing background apps.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        ListTile(
          leading: Icon(
            _isExempted == true ? Icons.battery_charging_full : Icons.battery_alert,
            color: _isExempted == true ? Colors.green : Colors.orange,
          ),
          title: const Text('Exempt from battery optimization'),
          subtitle: Text(_isExempted == true
              ? 'Already exempted on this device'
              : 'Tap to request - helps on most devices, but see note below for some brands'),
          trailing: _isExempted == true ? null : const Icon(Icons.chevron_right),
          onTap: _isExempted == true ? null : _requestExemption,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('If background fetch still stalls after that:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        const _OemGuidanceTile(
          brand: 'Honor / Huawei (MagicOS)',
          steps: 'Settings -> Battery -> App launch -> find Resonance -> switch to "Manage manually" -> '
              'enable all three: Auto-launch, Secondary launch, Run in background.',
        ),
        const _OemGuidanceTile(
          brand: 'Xiaomi / Redmi / POCO (MIUI/HyperOS)',
          steps: 'Settings -> Apps -> Manage apps -> Resonance -> Battery saver -> set to "No restrictions". '
              'Also check Autostart is enabled for Resonance.',
        ),
        const _OemGuidanceTile(
          brand: 'Oppo / Realme / OnePlus (ColorOS/OxygenOS, some versions)',
          steps: 'Settings -> Battery -> App Battery Management -> Resonance -> Allow background activity.',
        ),
        const _OemGuidanceTile(
          brand: 'Vivo (FuntouchOS/OriginOS)',
          steps: 'Settings -> Battery -> Background power consumption management -> Resonance -> Allow.',
        ),
        const _OemGuidanceTile(
          brand: 'Samsung (One UI)',
          steps: 'Settings -> Apps -> Resonance -> Battery -> set to "Unrestricted" (not "Optimized").',
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OemGuidanceTile extends StatelessWidget {
  final String brand;
  final String steps;

  const _OemGuidanceTile({required this.brand, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.smartphone, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                children: [
                  TextSpan(text: '$brand: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: steps),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}