package com.inibudi.screentimeshield.services

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.inibudi.screentimeshield.MainActivity
import com.inibudi.screentimeshield.utils.OverlayHelper
import com.inibudi.screentimeshield.utils.UsageStatsHelper
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Native Android Foreground Service for continuous app monitoring.
 *
 * Supports:
 * - Hard Lock Mode (5s full lock overlay -> kick to Home screen)
 * - Snooze Alarm Mode (Interactive +5m, +15m, +30m snooze buttons overlay)
 */
class AppMonitorService : Service() {

    companion object {
        private const val CHANNEL_ID = "screen_time_monitor_channel"
        private const val NOTIFICATION_ID = 1001
        private const val MONITOR_INTERVAL_MS = 1000L
        private const val LOCK_DELAY_BEFORE_HOME_MS = 5000L

        private const val ACTION_UPDATE_CONFIG = "com.inibudi.screentimeshield.UPDATE_CONFIG"
        private const val EXTRA_MONITORED_APPS = "monitored_apps_json"

        fun start(context: Context) {
            val intent = Intent(context, AppMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, AppMonitorService::class.java)
            context.stopService(intent)
        }

        fun updateMonitoredApps(context: Context, jsonString: String) {
            val intent = Intent(context, AppMonitorService::class.java).apply {
                action = ACTION_UPDATE_CONFIG
                putExtra(EXTRA_MONITORED_APPS, jsonString)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    data class AppConfig(
        val packageName: String,
        val appName: String,
        val timeLimitMs: Long,
        val lockMode: String = "hardLock",
        /** Per-weekday limits in minutes, keyed by Calendar.DAY_OF_WEEK (1 = Sunday). */
        val weeklyLimits: Map<Int, Int> = emptyMap()
    )

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageStatsHelper: UsageStatsHelper
    private lateinit var overlayHelper: OverlayHelper
    private lateinit var activityManager: ActivityManager

    private val monitoredAppsMap = HashMap<String, AppConfig>()
    private val lockStartTimeMap = HashMap<String, Long>()
    private val snoozeExpirationMap = HashMap<String, Long>()

    private val monitorRunnable = object : Runnable {
        override fun run() {
            checkCurrentApp()
            handler.postDelayed(this, MONITOR_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        usageStatsHelper = UsageStatsHelper(applicationContext)
        overlayHelper = OverlayHelper(applicationContext)
        activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        loadSavedConfigOnStart()
        handler.post(monitorRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_UPDATE_CONFIG) {
            val jsonStr = intent.getStringExtra(EXTRA_MONITORED_APPS)
            if (!jsonStr.isNullOrEmpty()) {
                parseAndStoreConfig(jsonStr)
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(monitorRunnable)
        overlayHelper.dismissLockOverlay()
        overlayHelper.dismissSnoozeOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkCurrentApp() {
        if (monitoredAppsMap.isEmpty()) {
            overlayHelper.dismissLockOverlay()
            overlayHelper.dismissSnoozeOverlay()
            lockStartTimeMap.clear()
            snoozeExpirationMap.clear()
            return
        }

        val currentPackage = usageStatsHelper.getCurrentForegroundApp() ?: return

        // Skip monitoring if the user is in our own app or launcher
        if (currentPackage == packageName || currentPackage.contains("launcher")) {
            overlayHelper.dismissLockOverlay()
            overlayHelper.dismissSnoozeOverlay()
            return
        }

        val config = monitoredAppsMap[currentPackage]
        val effectiveLimitMs = config?.let { resolveEffectiveLimitMs(it) } ?: 0L
        if (config != null && effectiveLimitMs > 0) {
            val todayUsageMs = usageStatsHelper.getTodayUsageForPackage(currentPackage)

            if (todayUsageMs >= effectiveLimitMs) {
                if (config.lockMode == "snoozeAlarm") {
                    val snoozeUntil = snoozeExpirationMap[currentPackage] ?: 0L
                    val now = System.currentTimeMillis()

                    if (now < snoozeUntil) {
                        // Currently within active snooze period -> Allow usage
                        overlayHelper.dismissLockOverlay()
                        overlayHelper.dismissSnoozeOverlay()
                    } else {
                        // Snooze expired or not set yet -> Display Snooze Alarm Overlay!
                        overlayHelper.dismissLockOverlay()
                        overlayHelper.showSnoozeOverlay(config.appName) { chosenMinutes ->
                            val extendUntil = System.currentTimeMillis() + (chosenMinutes * 60 * 1000L)
                            snoozeExpirationMap[currentPackage] = extendUntil
                            overlayHelper.dismissSnoozeOverlay()
                        }
                    }
                } else {
                    // Hard Lock Mode
                    overlayHelper.dismissSnoozeOverlay()
                    overlayHelper.showLockOverlay(config.appName)

                    if (!lockStartTimeMap.containsKey(currentPackage)) {
                        lockStartTimeMap[currentPackage] = System.currentTimeMillis()
                    }

                    val startTime = lockStartTimeMap[currentPackage] ?: System.currentTimeMillis()
                    val elapsedMs = System.currentTimeMillis() - startTime

                    if (elapsedMs >= LOCK_DELAY_BEFORE_HOME_MS) {
                        kickToHomeScreen()
                        try {
                            activityManager.killBackgroundProcesses(currentPackage)
                        } catch (_: Exception) {}
                    }
                }
            } else {
                snoozeExpirationMap.remove(currentPackage)
                lockStartTimeMap.remove(currentPackage)
                overlayHelper.dismissLockOverlay()
                overlayHelper.dismissSnoozeOverlay()
            }
        } else {
            snoozeExpirationMap.remove(currentPackage)
            lockStartTimeMap.remove(currentPackage)
            overlayHelper.dismissLockOverlay()
            overlayHelper.dismissSnoozeOverlay()
        }
    }

    private fun kickToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(homeIntent)
    }

    private fun loadSavedConfigOnStart() {
        try {
            val prefs = getSharedPreferences("monitor_prefs", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("monitored_apps", null)
            if (!jsonStr.isNullOrEmpty()) {
                parseAndStoreConfig(jsonStr)
            }
        } catch (_: Exception) {}
    }

    private fun parseAndStoreConfig(jsonStr: String) {
        try {
            val jsonArray = JSONArray(jsonStr)
            monitoredAppsMap.clear()

            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val pkg = obj.getString("packageName")
                val appName = obj.optString("appName", pkg)
                val timeLimitMs = obj.getLong("timeLimitMs")
                val lockMode = obj.optString("lockMode", "hardLock")

                monitoredAppsMap[pkg] = AppConfig(
                    packageName = pkg,
                    appName = appName,
                    timeLimitMs = timeLimitMs,
                    lockMode = lockMode,
                    weeklyLimits = parseWeeklyLimits(obj.optJSONObject("weeklyLimits"))
                )
            }

            val prefs = getSharedPreferences("monitor_prefs", Context.MODE_PRIVATE)
            prefs.edit().putString("monitored_apps", jsonStr).apply()
        } catch (_: Exception) {}
    }

    /**
     * Reads the per-weekday schedule. Payloads saved before this feature existed
     * have no "weeklyLimits" key, so a missing/blank object means "no schedule"
     * and every day keeps using the global time limit.
     */
    private fun parseWeeklyLimits(json: JSONObject?): Map<Int, Int> {
        if (json == null || json.length() == 0) return emptyMap()
        val result = HashMap<Int, Int>()
        for (day in json.keys()) {
            val dayOfWeek = day.toIntOrNull() ?: continue
            if (dayOfWeek < Calendar.SUNDAY || dayOfWeek > Calendar.SATURDAY) continue
            if (json.isNull(day)) continue
            result[dayOfWeek] = json.optInt(day, 0)
        }
        return result
    }

    /**
     * Limit in force right now: today's scheduled minutes when the weekday is
     * scheduled on, otherwise the app's global limit. Resolved on every tick so
     * a schedule change takes effect at midnight without restarting the service.
     */
    private fun resolveEffectiveLimitMs(config: AppConfig): Long {
        val today = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        val minutes = config.weeklyLimits[today] ?: return config.timeLimitMs
        return minutes * 60 * 1000L
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ScreenTime Shield Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors app usage in the background"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ScreenTime Shield Active")
            .setContentText("Monitoring screen time limits")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
