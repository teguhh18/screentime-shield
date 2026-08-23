package com.inibudi.screentimeshield.receivers

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Device Administrator receiver for anti-cheat functionality.
 *
 * Registered in AndroidManifest with BIND_DEVICE_ADMIN permission.
 * When activated, prevents the app from being uninstalled through
 * the normal Settings → Apps → Uninstall flow.
 *
 * Per PRD: Anti-Cheat — Prevents uninstall without PIN verification.
 */
class ScreenTimeDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "DeviceAdminReceiver"
    }

    /**
     * Called when the user enables Device Admin for this app.
     */
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device Admin enabled for ScreenTime Shield")
    }

    /**
     * Called when the user attempts to disable Device Admin.
     * Returns a warning message shown in the system dialog.
     */
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Disabling Device Admin will allow the app to be uninstalled. " +
            "Are you sure you want to continue?"
    }

    /**
     * Called when Device Admin has been disabled.
     */
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "Device Admin disabled for ScreenTime Shield")
    }
}
