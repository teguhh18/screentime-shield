package com.inibudi.screentimeshield

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.inibudi.screentimeshield.services.AppMonitorService
import com.inibudi.screentimeshield.utils.ChannelResult
import com.inibudi.screentimeshield.utils.DeviceAdminHelper
import com.inibudi.screentimeshield.utils.OverlayHelper
import com.inibudi.screentimeshield.utils.UsageStatsHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONArray

/**
 * Main entry point for the Android native layer.
 *
 * Per SKILL.md: This is a THIN ROUTER only.
 * MainActivity routes calls to helper classes.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_USAGE_STATS = "com.inibudi.screentimeshield/usage_stats"
        private const val CHANNEL_APP_LOCK = "com.inibudi.screentimeshield/app_lock"
        private const val CHANNEL_DEVICE_ADMIN = "com.inibudi.screentimeshield/device_admin"
        private const val CHANNEL_DEVICE_SECURITY = "com.inibudi.screentimeshield/device_security"

        private const val REQUEST_CODE_CONFIRM_CREDENTIAL = 9001
    }

    private lateinit var usageStatsHelper: UsageStatsHelper
    private lateinit var overlayHelper: OverlayHelper
    private lateinit var deviceAdminHelper: DeviceAdminHelper

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var pendingAdminResult: MethodChannel.Result? = null
    private var pendingCredentialResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usageStatsHelper = UsageStatsHelper(applicationContext)
        overlayHelper = OverlayHelper(applicationContext)
        deviceAdminHelper = DeviceAdminHelper(applicationContext)

        registerUsageStatsChannel(flutterEngine)
        registerAppLockChannel(flutterEngine)
        registerDeviceAdminChannel(flutterEngine)
        registerDeviceSecurityChannel(flutterEngine)
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun registerUsageStatsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_USAGE_STATS
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    sendResult(result, usageStatsHelper.checkPermission())
                }
                "requestPermission" -> {
                    sendResult(result, usageStatsHelper.requestPermission())
                }
                "getUsageStats" -> {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    if (startTime == null || endTime == null) {
                        result.error("INVALID_ARGS", "startTime and endTime required", null)
                        return@setMethodCallHandler
                    }
                    scope.launch {
                        sendResult(result, usageStatsHelper.getUsageStats(startTime, endTime))
                    }
                }
                "getInstalledApps" -> {
                    scope.launch {
                        sendResult(result, usageStatsHelper.getInstalledApps())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerAppLockChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_APP_LOCK
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    AppMonitorService.start(applicationContext)
                    result.success(true)
                }
                "stopService" -> {
                    AppMonitorService.stop(applicationContext)
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    sendResult(result, overlayHelper.checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    sendResult(result, overlayHelper.requestOverlayPermission())
                }
                "updateMonitoredApps" -> {
                    handleUpdateMonitoredApps(call, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleUpdateMonitoredApps(call: MethodCall, result: MethodChannel.Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val apps = call.argument<List<Map<String, Any>>>("apps")
            if (apps == null) {
                result.error("INVALID_ARGS", "apps list required", null)
                return
            }

            val jsonArray = JSONArray()
            for (app in apps) {
                val jsonObj = org.json.JSONObject()
                jsonObj.put("packageName", app["packageName"] as String)
                jsonObj.put("appName", app["appName"] as? String ?: app["packageName"])
                jsonObj.put("timeLimitMs", (app["timeLimitMs"] as Number).toLong())
                jsonObj.put("lockMode", app["lockMode"] as? String ?: "hardLock")

                // Per-weekday limits in minutes. Keys are Calendar.DAY_OF_WEEK
                // (1 = Sunday), matching Dart's JSON keys from MonitoredApp.
                val weeklyJson = org.json.JSONObject()
                val weekly = app["weeklyLimits"] as? Map<*, *>
                weekly?.forEach { (day, minutes) ->
                    if (day != null && minutes is Number) {
                        weeklyJson.put(day.toString(), minutes.toInt())
                    }
                }
                jsonObj.put("weeklyLimits", weeklyJson)

                jsonArray.put(jsonObj)
            }

            AppMonitorService.updateMonitoredApps(applicationContext, jsonArray.toString())
            result.success(true)
        } catch (e: Exception) {
            result.error("UPDATE_FAILED", "Failed to update monitored apps: ${e.message}", null)
        }
    }

    private fun registerDeviceAdminChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_DEVICE_ADMIN
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAdminStatus" -> {
                    sendResult(result, deviceAdminHelper.checkAdminStatus())
                }
                "requestAdmin" -> {
                    pendingAdminResult = result
                    sendResult(result, deviceAdminHelper.requestAdmin(this))
                }
                "removeAdmin" -> {
                    sendResult(result, deviceAdminHelper.removeAdmin())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerDeviceSecurityChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_DEVICE_SECURITY
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceSecure" -> {
                    val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                    result.success(keyguardManager.isDeviceSecure)
                }
                "confirmDeviceCredential" -> {
                    val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                    if (!keyguardManager.isDeviceSecure) {
                        // No lock screen set on device -> auto-pass
                        result.success(true)
                        return@setMethodCallHandler
                    }

                    @Suppress("DEPRECATION")
                    val intent = keyguardManager.createConfirmDeviceCredentialIntent(
                        "Verifikasi Identitas",
                        "Masukkan PIN/Password/Pola perangkat untuk melanjutkan."
                    )

                    if (intent != null) {
                        pendingCredentialResult = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, REQUEST_CODE_CONFIRM_CREDENTIAL)
                    } else {
                        // Could not create intent -> treat as no security set
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Using deprecated API for Device Admin and Keyguard result callbacks")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            DeviceAdminHelper.REQUEST_CODE_ENABLE_ADMIN -> {
                pendingAdminResult = null
            }
            REQUEST_CODE_CONFIRM_CREDENTIAL -> {
                val verified = resultCode == Activity.RESULT_OK
                pendingCredentialResult?.success(verified)
                pendingCredentialResult = null
            }
        }
    }

    private fun sendResult(result: MethodChannel.Result, channelResult: ChannelResult) {
        when (channelResult) {
            is ChannelResult.Success -> result.success(channelResult.data)
            is ChannelResult.Error -> result.error(
                channelResult.code,
                channelResult.message,
                channelResult.details
            )
        }
    }
}
