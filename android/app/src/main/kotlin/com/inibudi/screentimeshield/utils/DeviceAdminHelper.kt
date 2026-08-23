package com.inibudi.screentimeshield.utils

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.inibudi.screentimeshield.receivers.ScreenTimeDeviceAdminReceiver

/**
 * Helper for Device Administrator operations (anti-cheat).
 *
 * Manages:
 * - Checking if the app is an active Device Admin
 * - Requesting Device Admin activation
 * - Removing Device Admin (safe uninstall path)
 *
 * Per SKILL.md: Logic separated from MainActivity.
 */
class DeviceAdminHelper(private val context: Context) {

    private val devicePolicyManager: DevicePolicyManager by lazy {
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }

    private val adminComponent: ComponentName by lazy {
        ComponentName(context, ScreenTimeDeviceAdminReceiver::class.java)
    }

    companion object {
        /** Request code for Device Admin activation intent. */
        const val REQUEST_CODE_ENABLE_ADMIN = 1001
    }

    // ── Status Check ────────────────────────────────────────────────

    /**
     * Checks if this app is currently a Device Administrator.
     */
    fun checkAdminStatus(): ChannelResult {
        return try {
            val isAdmin = devicePolicyManager.isAdminActive(adminComponent)
            ChannelResult.Success(isAdmin)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "ADMIN_CHECK_FAILED",
                message = "Failed to check device admin status: ${e.message}"
            )
        }
    }

    // ── Activation ──────────────────────────────────────────────────

    /**
     * Launches the system intent to request Device Admin activation.
     *
     * @param activity The activity to launch the intent from (needed for result callback).
     */
    fun requestAdmin(activity: Activity): ChannelResult {
        return try {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                putExtra(
                    DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "ScreenTime Shield needs Device Administrator access " +
                        "to prevent the app from being uninstalled by your child."
                )
            }
            activity.startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
            ChannelResult.Success(true)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "ADMIN_REQUEST_FAILED",
                message = "Failed to request device admin activation: ${e.message}"
            )
        }
    }

    // ── Removal ─────────────────────────────────────────────────────

    /**
     * Removes Device Admin privilege.
     *
     * This should only be called AFTER PIN verification on the Flutter side.
     * Once removed, the app can be uninstalled normally.
     */
    fun removeAdmin(): ChannelResult {
        return try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.removeActiveAdmin(adminComponent)
                ChannelResult.Success(true)
            } else {
                ChannelResult.Success(false) // Already not admin
            }
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "ADMIN_REMOVE_FAILED",
                message = "Failed to remove device admin: ${e.message}"
            )
        }
    }
}
