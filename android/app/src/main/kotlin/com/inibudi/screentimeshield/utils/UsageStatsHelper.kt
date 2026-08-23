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
import android.os.Process
import android.provider.Settings
import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * Helper class wrapping [UsageStatsManager] for querying app usage data.
 * Uses queryAndAggregateUsageStats to prevent double-counting across interval buckets.
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

    /**
     * Queries per-app aggregated usage statistics for the given time range.
     * Uses queryAndAggregateUsageStats to ensure single clean entry per package.
     */
    suspend fun getUsageStats(startTime: Long, endTime: Long): ChannelResult {
        return withContext(Dispatchers.IO) {
            try {
                val aggregatedStatsMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)

                if (aggregatedStatsMap.isNullOrEmpty()) {
                    return@withContext ChannelResult.Success(emptyList<Map<String, Any>>())
                }

                val result = aggregatedStatsMap.values
                    .filter { it.totalTimeInForeground > 0 }
                    .map { stat ->
                        val appName = try {
                            val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                            packageManager.getApplicationLabel(appInfo).toString()
                        } catch (_: PackageManager.NameNotFoundException) {
                            stat.packageName
                        }

                        mapOf(
                            "packageName" to stat.packageName,
                            "appName" to appName,
                            "totalTimeInForeground" to stat.totalTimeInForeground
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
        val startTime = endTime - 1000 // Last 1 second

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        return stats
            ?.filter { it.totalTimeInForeground > 0 }
            ?.maxByOrNull { it.lastTimeUsed }
            ?.packageName
    }

    /**
     * Returns total foreground usage (in ms) for today starting from 00:00 midnight using queryAndAggregateUsageStats.
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

        val aggregatedStatsMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        return aggregatedStatsMap[packageName]?.totalTimeInForeground ?: 0L
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
