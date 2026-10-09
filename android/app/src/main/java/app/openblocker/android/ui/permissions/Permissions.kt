package app.openblocker.android.ui.permissions

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import app.openblocker.android.util.AccessibilityUtil

enum class PermissionKind {
    CAMERA,
    NOTIFICATIONS,
    ACCESSIBILITY
}

enum class PermissionStatus { GRANTED, NOT_DETERMINED, DENIED }

data class PermissionCopy(
    val kind: PermissionKind,
    val title: String,
    val message: String,
    val deniedTitle: String,
    val deniedMessage: String,
    val glyph: app.openblocker.android.ui.components.Glyph
)

object PermissionCopyCatalog {
    fun of(kind: PermissionKind): PermissionCopy = when (kind) {
        PermissionKind.CAMERA -> PermissionCopy(
            kind = kind,
            title = "Camera",
            message = "Open Blocker uses the camera only to scan your QR key.",
            deniedTitle = "Camera is off",
            deniedMessage = "Open Blocker uses the camera only to scan your QR key. Turn on Camera in Settings.",
            glyph = app.openblocker.android.ui.components.Glyph.Camera
        )
        PermissionKind.NOTIFICATIONS -> PermissionCopy(
            kind = kind,
            title = "Notifications",
            message = "Open Blocker can let you know when a block ends.",
            deniedTitle = "Notifications are off",
            deniedMessage = "Open Blocker can let you know when a block ends. Turn on Notifications in Settings.",
            glyph = app.openblocker.android.ui.components.Glyph.Bell
        )
        PermissionKind.ACCESSIBILITY -> PermissionCopy(
            kind = kind,
            title = "Accessibility",
            message = "Android requires Accessibility so we can block apps. We don't read your screen or track usage.",
            deniedTitle = "Accessibility is off",
            deniedMessage = "Android requires it to block apps. We don't read your usage. Turn it on in Settings, under Accessibility.",
            glyph = app.openblocker.android.ui.components.Glyph.Hourglass
        )
    }
}

object PermissionStatusReader {
    fun camera(context: Context): PermissionStatus {
        return when (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)) {
            PackageManager.PERMISSION_GRANTED -> PermissionStatus.GRANTED
            else -> if (wasAsked(context, "camera")) PermissionStatus.DENIED else PermissionStatus.NOT_DETERMINED
        }
    }

    fun notifications(context: Context): PermissionStatus {
        if (Build.VERSION.SDK_INT < 33) return PermissionStatus.GRANTED
        return when (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)) {
            PackageManager.PERMISSION_GRANTED -> PermissionStatus.GRANTED
            else -> if (wasAsked(context, "notifications")) PermissionStatus.DENIED else PermissionStatus.NOT_DETERMINED
        }
    }

    fun accessibility(context: Context): PermissionStatus {
        return if (AccessibilityUtil.isAccessibilityServiceEnabled(context)) {
            PermissionStatus.GRANTED
        } else {
            PermissionStatus.DENIED
        }
    }

    fun markAsked(context: Context, key: String) {
        context.getSharedPreferences("permission_asked", Context.MODE_PRIVATE)
            .edit().putBoolean(key, true).apply()
    }

    fun wasAsked(context: Context, key: String): Boolean {
        return context.getSharedPreferences("permission_asked", Context.MODE_PRIVATE)
            .getBoolean(key, false)
    }

    fun openAppSettings(context: Context) {
        context.startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.packageName, null)
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    fun openAccessibilitySettings(context: Context) {
        AccessibilityUtil.openAccessibilitySettings(context)
    }

    fun handleRuntime(
        status: PermissionStatus,
        request: () -> Unit,
        granted: () -> Unit,
        denied: () -> Unit
    ) {
        when (status) {
            PermissionStatus.GRANTED -> granted()
            PermissionStatus.NOT_DETERMINED -> request()
            PermissionStatus.DENIED -> denied()
        }
    }
}
