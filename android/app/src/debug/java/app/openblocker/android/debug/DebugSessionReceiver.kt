package app.openblocker.android.debug

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import app.openblocker.android.data.SessionManager

/**
 * Debug-build only. Start or stop a blocking session from adb without NFC.
 * Not compiled into release.
 *
 * adb shell am broadcast -a app.openblocker.android.debug.START_SESSION \
 *   -n app.openblocker.android/.debug.DebugSessionReceiver
 * adb shell am broadcast -a app.openblocker.android.debug.END_SESSION \
 *   -n app.openblocker.android/.debug.DebugSessionReceiver
 */
class DebugSessionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ACTION_START -> {
                SessionManager.startSession()
                Log.i(TAG, "debug start session")
                Toast.makeText(context, "Blocking session started", Toast.LENGTH_SHORT).show()
            }
            ACTION_END -> {
                SessionManager.endSession()
                Log.i(TAG, "debug end session")
                Toast.makeText(context, "Blocking session ended", Toast.LENGTH_SHORT).show()
            }
        }
    }

    companion object {
        const val ACTION_START = "app.openblocker.android.debug.START_SESSION"
        const val ACTION_END = "app.openblocker.android.debug.END_SESSION"
        private const val TAG = "DebugSessionReceiver"
    }
}
