import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:boostify/services/battery_service.dart';
import 'package:easy_localization/easy_localization.dart';

class BatteryInfoScreen extends StatefulWidget {
  const BatteryInfoScreen({super.key});

  @override
  State<BatteryInfoScreen> createState() => _BatteryInfoScreenState();
}

class _BatteryInfoScreenState extends State<BatteryInfoScreen> {
  Map<String, dynamic> batteryInfo = {};
  int batteryLevel = 0;
  BatteryState batteryState = BatteryState.unknown;

  @override
  void initState() {
    super.initState();
    _loadBatteryInfo();
  }

  Future<void> _loadBatteryInfo() async {
    final info = await BatteryService.getBatteryInfo();
    final level = await BatteryService.getBatteryLevel();
    final state = await BatteryService.getBatteryState();

    setState(() {
      batteryInfo = info;
      batteryLevel = level;
      batteryState = state;
    });
  }

  String _getBatteryStateText() {
    switch (batteryState) {
      case BatteryState.charging: return 'charging'.tr();
      case BatteryState.discharging: return 'discharging'.tr();
      case BatteryState.full: return 'battery_full'.tr();
      default: return 'unknown'.tr();
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blue, size: 32),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('battery_info'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBatteryInfo,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildInfoCard(
              title: 'battery_level'.tr(),
              value: '$batteryLevel%',
              icon: batteryState == BatteryState.charging 
                ? Icons.battery_charging_full 
                : Icons.battery_full,
              iconColor: batteryLevel > 20 ? Colors.green : Colors.red,
            ),
            _buildInfoCard(
              title: 'battery_status'.tr(),
              value: _getBatteryStateText(),
              icon: Icons.info_outline,
            ),
            if (batteryInfo['temperature'] != null)
              _buildInfoCard(
                title: 'battery_temperature'.tr(),
                value: '${batteryInfo['temperature']}°C',
                icon: Icons.thermostat,
                iconColor: Colors.orange,
              ),
            if (batteryInfo['voltage'] != null)
              _buildInfoCard(
                title: 'battery_voltage'.tr(),
                value: '${batteryInfo['voltage']}V',
                icon: Icons.electric_bolt,
                iconColor: Colors.yellow[700],
              ),
            if (batteryInfo['technology'] != null)
              _buildInfoCard(
                title: 'battery_technology'.tr(),
                value: batteryInfo['technology'],
                icon: Icons.memory,
              ),
            if (batteryInfo['health'] != null)
              _buildInfoCard(
                title: 'battery_health'.tr(),
                value: BatteryService.getBatteryHealthStatus(batteryInfo['health']),
                icon: Icons.favorite,
                iconColor: Colors.red,
              ),
          ],
        ),
      ),
    );
  }
} 