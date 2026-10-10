package app.openblocker.android.data

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import app.openblocker.android.OpenBlockerApplication

object SessionNotify {
    private const val PREFS = "notify_prefs"
    private const val KEY_ENABLED = "enabled"
    private const val CHANNEL_ID = "session"

    private val prefs by lazy {
        OpenBlockerApplication.getAppContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    var isEnabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, false)
        set(value) { prefs.edit().putBoolean(KEY_ENABLED, value).apply() }

    fun onBlockEnded() {
        if (!isEnabled) return
        val context = OpenBlockerApplication.getAppContext()
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle("Block ended")
            .setContentText("Your block has ended.")
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(42, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Blocks", NotificationManager.IMPORTANCE_DEFAULT)
        )
    }
}
