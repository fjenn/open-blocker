package app.openblocker.android.service

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.ui.BlockScreenActivity

class AppBlockingService : AccessibilityService() {
    
    private var lastBlockedTime = 0L
    private val blockCooldownMs = 1000L
    private var hasRecordedFirstBlock = false
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        
        if (!SessionManager.isBlocking.value) {
            return
        }
        
        val packageName = event.packageName?.toString() ?: return
        
        if (packageName == "app.openblocker.android") {
            return
        }
        
        val blockedApps = PreferencesManager.getBlockedApps()
        if (blockedApps.contains(packageName)) {
            val now = System.currentTimeMillis()
            if (now - lastBlockedTime > blockCooldownMs) {
                lastBlockedTime = now
                showBlockScreen()
                
                if (!hasRecordedFirstBlock) {
                    hasRecordedFirstBlock = true
                    CountManager.recordFirstBlock()
                }
            }
        }
    }
    
    override fun onInterrupt() {
    }
    
    private fun showBlockScreen() {
        val intent = Intent(this, BlockScreenActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
        }
        startActivity(intent)
    }
}
