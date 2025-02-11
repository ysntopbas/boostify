package com.example.boostify

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.BatteryManager
import android.content.Intent
import android.content.IntentFilter
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.provider.Settings

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.boostify/system"
    private val BATTERY_CHANNEL = "com.boostify/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRamUsage" -> {
                    result.success(getRamUsage())
                }
                "cleanRam" -> {
                    cleanRam()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryTemperature" -> {
                    result.success(getBatteryTemperature())
                }
                "getBatteryVoltage" -> {
                    result.success(getBatteryVoltage())
                }
                "getBatteryTechnology" -> {
                    result.success(getBatteryTechnology())
                }
                "getBatteryHealth" -> {
                    result.success(getBatteryHealth())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getRamUsage(): Double {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val totalMemory = memoryInfo.totalMem.toDouble()
        val availableMemory = memoryInfo.availMem.toDouble()
        
        return (totalMemory - availableMemory) / totalMemory
    }

    private fun cleanRam() {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.let {
            it.getRunningAppProcesses()?.forEach { processInfo ->
                it.killBackgroundProcesses(processInfo.processName)
            }
        }
    }

    private fun getBatteryTemperature(): Float {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return temp / 10.0f
    }

    private fun getBatteryVoltage(): Float {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        return voltage / 1000.0f
    }

    private fun getBatteryTechnology(): String {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Unknown"
    }

    private fun getBatteryHealth(): Int {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) 
            ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
    }
}
