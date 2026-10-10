package app.openblocker.android

import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.DomainMatch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DomainMatchTest {

    @Test
    fun stripsSchemeWwwPathAndPort() {
        assertEquals("youtube.com", DomainMatch.hostOf("https://www.youtube.com/watch?v=dQw4w9wg"))
        assertEquals("youtube.com", DomainMatch.hostOf("http://youtube.com/feed"))
        assertEquals("youtube.com", DomainMatch.hostOf("youtube.com"))
        assertEquals("youtube.com", DomainMatch.hostOf("www.youtube.com"))
        assertEquals("youtube.com", DomainMatch.hostOf("https://youtube.com:443/path"))
        assertEquals("youtube.com", DomainMatch.hostOf("//www.youtube.com/shorts"))
    }

    @Test
    fun matchesSubdomainsAndRejectsCousins() {
        assertTrue(DomainMatch.matches("https://m.youtube.com/watch", "youtube.com"))
        assertTrue(DomainMatch.matches("music.youtube.com", "youtube.com"))
        assertTrue(DomainMatch.matches("www.youtube.com", "youtube.com"))
        assertTrue(DomainMatch.matches("youtube.com", "www.youtube.com"))
        assertFalse(DomainMatch.matches("notyoutube.com", "youtube.com"))
        assertFalse(DomainMatch.matches("youtube.com.evil.test", "youtube.com"))
        assertFalse(DomainMatch.matches("myyoutube.com", "youtube.com"))
    }

    @Test
    fun ignoresSearchTextAndEmpty() {
        assertNull(DomainMatch.hostOf(""))
        assertNull(DomainMatch.hostOf("   "))
        assertNull(DomainMatch.hostOf("cats and dogs"))
        assertNull(DomainMatch.hostOf("Search or type web address"))
        assertNull(DomainMatch.hostOf("youtube"))
        assertFalse(DomainMatch.matches("cats and dogs", "youtube.com"))
    }

    @Test
    fun blockModeBlocksOnlyListedHosts() {
        val mode = BlockMode(
            name = "Deep work",
            kind = BlockMode.Kind.BLOCK,
            websites = listOf("youtube.com", "https://www.reddit.com/r/all")
        )
        assertTrue(mode.shouldBlockHost("https://www.youtube.com/watch?v=1"))
        assertTrue(mode.shouldBlockHost("old.reddit.com"))
        assertFalse(mode.shouldBlockHost("https://wikipedia.org"))
        assertFalse(mode.shouldBlockHost("Search or type web address"))
    }

    @Test
    fun allowOnlyBlocksHostsNotOnTheList() {
        val mode = BlockMode(
            name = "Sleep",
            kind = BlockMode.Kind.ALLOW_ONLY,
            websites = listOf("wikipedia.org", "http://maps.google.com")
        )
        assertFalse(mode.shouldBlockHost("https://en.wikipedia.org/wiki/Sleep"))
        assertFalse(mode.shouldBlockHost("maps.google.com/dir"))
        assertTrue(mode.shouldBlockHost("https://youtube.com"))
        assertTrue(mode.shouldBlockHost("news.ycombinator.com"))
    }

    @Test
    fun allowOnlyWithEmptyListBlocksEveryHost() {
        val mode = BlockMode(name = "Detox", kind = BlockMode.Kind.ALLOW_ONLY)
        assertTrue(mode.shouldBlockHost("https://example.com"))
        assertFalse(mode.shouldBlockHost("not a url"))
    }

    @Test
    fun blockModeWithEmptyListBlocksNoHosts() {
        val mode = BlockMode(name = "Blank", kind = BlockMode.Kind.BLOCK)
        assertFalse(mode.shouldBlockHost("https://youtube.com"))
    }
}
