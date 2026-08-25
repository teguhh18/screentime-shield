package com.inibudi.screentimeshield.utils

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.app.usage.UsageEvents
import android.os.Process
import android.provider.Settings
import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * Helper class wrapping [UsageStatsManager] for querying app usage data.
 * Computes daily usage from the event stream (queryEvents) so totals
 * match Android's Digital Wellbeing exactly.
 */
class UsageStatsHelper(private val context: Context) {

    private val usageStatsManager: UsageStatsManager by lazy {
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }

    private val packageManager: PackageManager by lazy {
        context.packageManager
    }

    // ── Permission Checks ───────────────────────────────────────────

    fun checkPermission(): ChannelResult {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            }
            ChannelResult.Success(mode == AppOpsManager.MODE_ALLOWED)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "USAGE_STATS_CHECK_FAILED",
                message = "Failed to check usage stats permission: ${e.message}"
            )
        }
    }

    fun requestPermission(): ChannelResult {
        return try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            ChannelResult.Success(true)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "USAGE_STATS_REQUEST_FAILED",
                message = "Failed to open usage stats settings: ${e.message}"
            )
        }
    }

    // ── Usage Data Queries ──────────────────────────────────────────

    companion object {
        private const val DAY_MS = 24 * 60 * 60 * 1000L
    }

    /**
     * Computes per-app foreground usage (in ms) within [startTime, endTime] by
     * replaying foreground/background events, clamping sessions to the query range.
     *
     * This matches Digital Wellbeing's calculation. Do NOT use
     * queryAndAggregateUsageStats for daily totals: its totalTimeInForeground
     * covers the whole stats bucket (which may start before the query range),
     * causing inflated numbers that don't match the system screen time.
     */
    private fun computeUsageFromEvents(startTime: Long, endTime: Long): HashMap<String, Long> {
        val usageMap = HashMap<String, Long>()
        val lastResumeMap = HashMap<String, Long>()

        // Look back one extra day so sessions spanning midnight are handled:
        // a session resumed yesterday and paused today must only count today's part.
        val usageEvents = usageStatsManager.queryEvents(startTime - DAY_MS, endTime)
        val event = UsageEvents.Event()

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            @Suppress("DEPRECATION")
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> lastResumeMap[event.packageName] = event.timeStamp
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    lastResumeMap.remove(event.packageName)?.let { resumeTime ->
                        val from = maxOf(resumeTime, startTime)
                        val to = minOf(event.timeStamp, endTime)
                        if (to > from) {
                            usageMap[event.packageName] = (usageMap[event.packageName] ?: 0L) + (to - from)
                        }
                    }
                }
            }
        }

        // Sessions still open at endTime (app currently in foreground)
        for ((pkg, resumeTime) in lastResumeMap) {
            val from = maxOf(resumeTime, startTime)
            if (endTime > from) {
                usageMap[pkg] = (usageMap[pkg] ?: 0L) + (endTime - from)
            }
        }

        return usageMap
    }

    /**
     * Queries per-app usage statistics for the given time range,
     * computed from the event stream so totals match Android's
     * Digital Wellbeing exactly.
     */
    suspend fun getUsageStats(startTime: Long, endTime: Long): ChannelResult {
        return withContext(Dispatchers.IO) {
            try {
                val usageMap = computeUsageFromEvents(startTime, endTime)

                if (usageMap.isEmpty()) {
                    return@withContext ChannelResult.Success(emptyList<Map<String, Any>>())
                }

                val result = usageMap
                    .filter { it.value > 0 }
                    .map { (packageName, usageMs) ->
                        val appName = try {
                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                            packageManager.getApplicationLabel(appInfo).toString()
                        } catch (_: PackageManager.NameNotFoundException) {
                            packageName
                        }

                        mapOf(
                            "packageName" to packageName,
                            "appName" to appName,
                            "totalTimeInForeground" to usageMs
                        )
                    }
                    .sortedByDescending { it["totalTimeInForeground"] as Long }

                ChannelResult.Success(result)
            } catch (e: SecurityException) {
                ChannelResult.Error(
                    code = "PERMISSION_DENIED",
                    message = "Usage stats permission not granted."
                )
            } catch (e: Exception) {
                ChannelResult.Error(
                    code = "USAGE_STATS_QUERY_FAILED",
                    message = "Failed to query usage stats: ${e.message}"
                )
            }
        }
    }

    suspend fun getInstalledApps(): ChannelResult {
        return withContext(Dispatchers.IO) {
            try {
                val mainIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }

                val resolvedApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    packageManager.queryIntentActivities(
                        mainIntent,
                        PackageManager.ResolveInfoFlags.of(0)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    packageManager.queryIntentActivities(mainIntent, 0)
                }

                val result = resolvedApps
                    .filter { it.activityInfo.packageName != context.packageName }
                    .map { resolveInfo ->
                        val appInfo = resolveInfo.activityInfo.applicationInfo
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        val iconBase64 = try {
                            val drawable = packageManager.getApplicationIcon(appInfo)
                            drawableToBase64(drawable)
                        } catch (_: Exception) {
                            ""
                        }

                        mapOf(
                            "packageName" to resolveInfo.activityInfo.packageName,
                            "appName" to appName,
                            "icon" to iconBase64
                        )
                    }
                    .sortedBy { it["appName"] as String }

                ChannelResult.Success(result)
            } catch (e: Exception) {
                ChannelResult.Error(
                    code = "INSTALLED_APPS_FAILED",
                    message = "Failed to get installed apps: ${e.message}"
                )
            }
        }
    }

    // ── Current Foreground App & Today Usage ────────────────────────

    fun getCurrentForegroundApp(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 30_000 // Look back 30s for the latest transition

        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        var latestEventTime = -1L
        var latestPackage: String? = null

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            @Suppress("DEPRECATION")
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND &&
                event.timeStamp > latestEventTime
            ) {
                latestEventTime = event.timeStamp
                latestPackage = event.packageName
            }
        }

        return latestPackage
    }

    /**
     * Returns total foreground usage (in ms) for today starting from 00:00 midnight.
     * Uses the same event-based calculation as the UI so the lock trigger
     * and the displayed usage are always in sync.
     */
    fun getTodayUsageForPackage(packageName: String): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        return computeUsageFromEvents(startTime, endTime)[packageName] ?: 0L
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val width = drawable.intrinsicWidth.coerceAtLeast(1)
            val height = drawable.intrinsicHeight.coerceAtLeast(1)
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
        val bytes = stream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }
}
