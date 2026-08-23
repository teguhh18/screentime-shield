package com.inibudi.screentimeshield.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts [AppMonitorService] after device reboot.
 *
 * Registered in AndroidManifest with BOOT_COMPLETED intent filter
 * to ensure the monitoring service survives device restarts.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Only restart if there are monitored apps configured
            val prefs = context.getSharedPreferences("monitor_prefs", Context.MODE_PRIVATE)
            val appsJson = prefs.getString("monitored_apps", "[]") ?: "[]"

            if (appsJson != "[]" && appsJson.isNotEmpty()) {
                AppMonitorService.start(context)
            }
        }
    }
}
