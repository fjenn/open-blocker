package app.openblocker.android.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyCodecTest {

    @Test
    fun roundTripNamedKeys() {
        val keys = listOf(
            StoredKey(
                id = "a",
                name = "Fridge QR",
                kind = StoredKey.Kind.QR,
                secret = "openblocker://tag/v1/05d9792dbd4f41965ee9a1ea91f06d9f",
                addedAtMs = 1_700_000_000_000L
            ),
            StoredKey(
                id = "b",
                name = "Desk tag",
                kind = StoredKey.Kind.NFC_TAG,
                secret = KeyStore.MOCK_NFC_UID,
                addedAtMs = 1_700_000_100_000L
            )
        )
        val decoded = KeyCodec.decode(KeyCodec.encode(keys))
        assertEquals(keys, decoded)
    }

    @Test
    fun addedAgoMatchesIosRelativeBuckets() {
        val now = 1_800_000_000_000L
        assertEquals("just now", KeyCodec.addedAgo(now - 10_000, now))
        assertEquals("1 minute ago", KeyCodec.addedAgo(now - 60_000, now))
        assertEquals("3 minutes ago", KeyCodec.addedAgo(now - 180_000, now))
        assertEquals("1 hour ago", KeyCodec.addedAgo(now - 3_600_000, now))
        assertEquals("2 hours ago", KeyCodec.addedAgo(now - 7_200_000, now))
        assertEquals("24 hours ago", KeyCodec.addedAgo(now - 86_400_000, now))
        assertEquals("1 day ago", KeyCodec.addedAgo(now - 40 * 3_600_000, now))
        assertEquals("3 days ago", KeyCodec.addedAgo(now - 3 * 86_400_000, now))
    }

    @Test
    fun kindTitlesMatchIos() {
        assertEquals("QR code", StoredKey.Kind.QR.title)
        assertEquals("NFC tag", StoredKey.Kind.NFC_TAG.title)
        assertEquals("NFC card", StoredKey.Kind.CARD.title)
        assertEquals("Fridge QR", StoredKey.Kind.QR.placeholder)
        assertEquals("Desk tag", StoredKey.Kind.NFC_TAG.placeholder)
        assertEquals("Gym card", StoredKey.Kind.CARD.placeholder)
        assertTrue(KeyStore.MOCK_NFC_UID == "04a1b2c3d4e5f6")
    }
}
