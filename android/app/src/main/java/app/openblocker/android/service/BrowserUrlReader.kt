package app.openblocker.android.service

import android.view.accessibility.AccessibilityNodeInfo

/**
 * Reads the address-bar text of supported browsers from the accessibility tree.
 *
 * Browser package names and URL-bar view IDs for Chrome, Firefox, Opera, and
 * Opera Mini follow the SupportedBrowserConfig list in MindMaster
 * (https://github.com/ArmanKhanTech/MindMaster, MIT License,
 * Copyright (c) 2023 Arman Khan). Additional Chromium / Gecko browsers use
 * the same public resource IDs those apps expose (not copied from GPL projects).
 */
object BrowserUrlReader {

    data class Browser(
        val packageName: String,
        val urlBarIds: List<String>
    ) {
        constructor(packageName: String, urlBarId: String) : this(packageName, listOf(urlBarId))
    }

    val browsers: List<Browser> = listOf(
        // MindMaster (MIT) SupportedBrowserConfig
        Browser("com.android.chrome", "com.android.chrome:id/url_bar"),
        Browser("org.mozilla.firefox", "org.mozilla.firefox:id/mozac_browser_toolbar_url_view"),
        Browser("com.opera.browser", "com.opera.browser:id/url_field"),
        Browser("com.opera.mini.native", "com.opera.mini.native:id/url_field"),
        // Same public view IDs on Chromium / Gecko forks. Not copied from GPL sources.
        Browser("com.chrome.beta", "com.chrome.beta:id/url_bar"),
        Browser("com.chrome.dev", "com.chrome.dev:id/url_bar"),
        Browser("com.chrome.canary", "com.chrome.canary:id/url_bar"),
        Browser("com.brave.browser", "com.brave.browser:id/url_bar"),
        Browser("com.brave.browser_beta", "com.brave.browser_beta:id/url_bar"),
        Browser("com.microsoft.emmx", "com.microsoft.emmx:id/url_bar"),
        Browser("com.microsoft.emmx.beta", "com.microsoft.emmx.beta:id/url_bar"),
        Browser("com.vivaldi.browser", "com.vivaldi.browser:id/url_bar"),
        Browser("com.sec.android.app.sbrowser", listOf(
            "com.sec.android.app.sbrowser:id/location_bar_edit_text",
            "com.sec.android.app.sbrowser:id/url_bar"
        )),
        Browser("org.mozilla.firefox_beta", "org.mozilla.firefox_beta:id/mozac_browser_toolbar_url_view"),
        Browser("org.mozilla.focus", listOf(
            "org.mozilla.focus:id/mozac_browser_toolbar_url_view",
            "org.mozilla.focus:id/display_url"
        )),
        Browser("org.mozilla.fenix", "org.mozilla.fenix:id/mozac_browser_toolbar_url_view"),
        Browser("com.duckduckgo.mobile.android", "com.duckduckgo.mobile.android:id/omnibarTextInput"),
        Browser("com.opera.browser.beta", "com.opera.browser.beta:id/url_field")
    )

    private val byPackage: Map<String, Browser> = browsers.associateBy { it.packageName }

    fun browserFor(packageName: String): Browser? = byPackage[packageName]

    fun isSupportedBrowser(packageName: String): Boolean = byPackage.containsKey(packageName)

    fun captureUrl(root: AccessibilityNodeInfo, packageName: String): String? {
        val browser = browserFor(packageName) ?: return null
        for (id in browser.urlBarIds) {
            val nodes = try {
                root.findAccessibilityNodeInfosByViewId(id)
            } catch (_: Exception) {
                null
            }
            if (nodes.isNullOrEmpty()) continue
            val text = nodes.firstNotNullOfOrNull { node ->
                sequenceOf(node.text, node.contentDescription)
                    .mapNotNull { it?.toString()?.trim() }
                    .firstOrNull { it.isNotEmpty() }
            }
            nodes.forEach { it.recycle() }
            if (!text.isNullOrEmpty()) return text
        }
        return null
    }
}
