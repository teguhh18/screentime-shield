package com.inibudi.screentimeshield.utils

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Helper for managing system overlays (Draw Over Other Apps).
 *
 * Handles:
 * - Checking and requesting SYSTEM_ALERT_WINDOW permission
 * - Displaying full-screen Hard Lock overlay
 * - Displaying interactive Snooze Alarm overlay with +5m, +15m, +30m buttons
 * - Triggering alarm sound & phone vibration during Snooze Alarm Overlay display
 */
class OverlayHelper(private val context: Context) {

    private val windowManager: WindowManager by lazy {
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    private var overlayView: View? = null
    private var snoozeOverlayView: View? = null

    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null

    // ── Permission Checks ───────────────────────────────────────────

    fun checkOverlayPermission(): ChannelResult {
        return try {
            val canDraw = Settings.canDrawOverlays(context)
            ChannelResult.Success(canDraw)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "OVERLAY_CHECK_FAILED",
                message = "Failed to check overlay permission: ${e.message}"
            )
        }
    }

    fun requestOverlayPermission(): ChannelResult {
        return try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            ChannelResult.Success(true)
        } catch (e: Exception) {
            ChannelResult.Error(
                code = "OVERLAY_REQUEST_FAILED",
                message = "Failed to open overlay permission settings: ${e.message}"
            )
        }
    }

    // ── Full Lock Overlay Display ────────────────────────────────────

    fun showLockOverlay(appName: String) {
        dismissSnoozeOverlay()

        if (overlayView != null) return // Already showing
        if (!Settings.canDrawOverlays(context)) return

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        overlayView = createLockView(appName)

        try {
            windowManager.addView(overlayView, params)
        } catch (_: Exception) {
            overlayView = null
        }
    }

    fun dismissLockOverlay() {
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {}
            overlayView = null
        }
    }

    // ── Snooze Alarm Overlay Display ─────────────────────────────────

    /**
     * Displays an interactive Snooze Alarm overlay with +5m, +15m, +30m options.
     * Triggers looping alarm sound & continuous phone vibration.
     */
    fun showSnoozeOverlay(
        appName: String,
        onSnoozeSelected: (minutes: Int) -> Unit
    ) {
        dismissLockOverlay()

        if (snoozeOverlayView != null) return // Already showing
        if (!Settings.canDrawOverlays(context)) return

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        snoozeOverlayView = createSnoozeView(appName, onSnoozeSelected)

        try {
            windowManager.addView(snoozeOverlayView, params)
            startAlarmSound()
            startVibration()
        } catch (_: Exception) {
            snoozeOverlayView = null
        }
    }

    fun dismissSnoozeOverlay() {
        stopAlarmSound()
        stopVibration()

        snoozeOverlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {}
            snoozeOverlayView = null
        }
    }

    fun isOverlayShowing(): Boolean = overlayView != null || snoozeOverlayView != null

    // ── Audio & Vibration Helpers ────────────────────────────────────

    private fun startAlarmSound() {
        try {
            if (ringtone == null) {
                val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

                ringtone = RingtoneManager.getRingtone(context, alarmUri)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    ringtone?.isLooping = true
                }
            }
            if (ringtone?.isPlaying == false) {
                ringtone?.play()
            }
        } catch (_: Exception) {}
    }

    private fun stopAlarmSound() {
        try {
            if (ringtone?.isPlaying == true) {
                ringtone?.stop()
            }
            ringtone = null
        } catch (_: Exception) {}
    }

    private fun startVibration() {
        try {
            if (vibrator == null) {
                vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                    vibratorManager.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Repeating pulse pattern: 0ms delay, 500ms vibrate, 500ms pause
                val pattern = longArrayOf(0, 500, 500)
                val effect = VibrationEffect.createWaveform(pattern, 0)
                vibrator?.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 500, 500), 0)
            }
        } catch (_: Exception) {}
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
            vibrator = null
        } catch (_: Exception) {}
    }

    // ── Private: Build Overlay Views ────────────────────────────────

    private fun createLockView(appName: String): View {
        val density = context.resources.displayMetrics.density

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E61A1A2E"))
            setPadding(
                (32 * density).toInt(),
                (32 * density).toInt(),
                (32 * density).toInt(),
                (32 * density).toInt()
            )
        }

        val iconView = TextView(context).apply {
            text = "🛡️"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 64f)
            gravity = Gravity.CENTER
        }
        container.addView(iconView)

        val titleView = TextView(context).apply {
            text = "Time's Up!"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, (16 * density).toInt(), 0, (8 * density).toInt())
        }
        container.addView(titleView)

        val messageView = TextView(context).apply {
            text = "Batas waktu penggunaan untuk $appName telah habis.\n\nAplikasi dikunci."
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, (24 * density).toInt())
        }
        container.addView(messageView)

        return container
    }

    private fun createSnoozeView(
        appName: String,
        onSnoozeSelected: (minutes: Int) -> Unit
    ): View {
        val density = context.resources.displayMetrics.density

        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E60F172A"))
            setPadding(
                (24 * density).toInt(),
                (24 * density).toInt(),
                (24 * density).toInt(),
                (24 * density).toInt()
            )
        }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#1E293B"))
                cornerRadius = 24 * density
            }
            setPadding(
                (24 * density).toInt(),
                (28 * density).toInt(),
                (24 * density).toInt(),
                (28 * density).toInt()
            )
        }

        val iconView = TextView(context).apply {
            text = "⏰"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 56f)
            gravity = Gravity.CENTER
        }
        card.addView(iconView)

        val titleView = TextView(context).apply {
            text = "Batas Waktu Tercapai!"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, (12 * density).toInt(), 0, (6 * density).toInt())
        }
        card.addView(titleView)

        val messageView = TextView(context).apply {
            text = "Batas waktu harian untuk $appName telah habis.\nPilih waktu tunda (Snooze):"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, (20 * density).toInt())
        }
        card.addView(messageView)

        val buttonColumn = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        fun buildSnoozeButton(label: String, colorHex: String, minutes: Int): Button {
            return Button(context).apply {
                text = label
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                typeface = Typeface.DEFAULT_BOLD
                background = GradientDrawable().apply {
                    setColor(Color.parseColor(colorHex))
                    cornerRadius = 14 * density
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    (48 * density).toInt()
                ).apply {
                    setMargins(0, (4 * density).toInt(), 0, (4 * density).toInt())
                }
                setOnClickListener {
                    onSnoozeSelected(minutes)
                }
            }
        }

        buttonColumn.addView(buildSnoozeButton("+5 Menit", "#F59E0B", 5))
        buttonColumn.addView(buildSnoozeButton("+15 Menit", "#3B82F6", 15))
        buttonColumn.addView(buildSnoozeButton("+30 Menit", "#10B981", 30))

        card.addView(buttonColumn)
        root.addView(card)

        return root
    }
}
