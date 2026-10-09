package app.openblocker.android.service

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.SessionManager
import app.openblocker.android.ui.BlockScreenActivity

class AppBlockingService : AccessibilityService() {

    private var lastBlockedTime = 0L
    private var lastUrlReadAt = 0L
    private var lastCapturedUrl: String? = null
    private val blockCooldownMs = 1000L
    private val urlSampleMs = 250L
    private var hasRecordedFirstBlock = false

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!SessionManager.isBlocking.value) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == "app.openblocker.android") return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            if (ModeRepository.shouldBlockPackage(packageName, "app.openblocker.android")) {
                fireBlock(website = false)
                return
            }
        }

        if (!BrowserUrlReader.isSupportedBrowser(packageName)) return
        if (!isUrlEvent(event.eventType)) return

        val now = System.currentTimeMillis()
        if (now - lastUrlReadAt < urlSampleMs) return
        lastUrlReadAt = now

        val root = rootInActiveWindow ?: return
        try {
            val captured = BrowserUrlReader.captureUrl(root, packageName) ?: return
            if (captured == lastCapturedUrl && now - lastBlockedTime < blockCooldownMs) return
            lastCapturedUrl = captured
            if (ModeRepository.shouldBlockHost(captured)) {
                fireBlock(website = true)
            }
        } finally {
            recycleQuietly(root)
        }
    }

    override fun onInterrupt() {
    }

    private fun isUrlEvent(type: Int): Boolean {
        return type == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED ||
            type == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED ||
            type == AccessibilityEvent.TYPE_VIEW_FOCUSED
    }

    private fun fireBlock(website: Boolean) {
        val now = System.currentTimeMillis()
        if (now - lastBlockedTime <= blockCooldownMs) return
        lastBlockedTime = now
        if (website) {
            performGlobalAction(GLOBAL_ACTION_BACK)
            performGlobalAction(GLOBAL_ACTION_HOME)
        }
        showBlockScreen(website)
        if (!hasRecordedFirstBlock) {
            hasRecordedFirstBlock = true
            CountManager.recordFirstBlock()
        }
    }

    private fun showBlockScreen(website: Boolean) {
        val intent = Intent(this, BlockScreenActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra(BlockScreenActivity.EXTRA_WEBSITE, website)
        }
        startActivity(intent)
    }

    private fun recycleQuietly(node: AccessibilityNodeInfo) {
        try {
            node.recycle()
        } catch (_: Exception) {
        }
    }
}
