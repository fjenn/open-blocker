package app.openblocker.android

import app.openblocker.android.service.BrowserUrlReader
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BrowserUrlReaderTest {

    @Test
    fun knownBrowsersHaveUrlBarIds() {
        val required = listOf(
            "com.android.chrome",
            "com.brave.browser",
            "com.microsoft.emmx",
            "org.mozilla.firefox",
            "com.sec.android.app.sbrowser",
            "com.opera.browser",
            "com.duckduckgo.mobile.android"
        )
        required.forEach { pkg ->
            val browser = BrowserUrlReader.browserFor(pkg)
            assertNotNull(pkg, browser)
            assertTrue(pkg, browser!!.urlBarIds.all { it.startsWith("$pkg:id/") })
        }
        assertEquals(required.size, required.distinct().size)
        assertTrue(BrowserUrlReader.browsers.size >= required.size)
    }
}