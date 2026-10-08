package app.openblocker.android.debug

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.util.zip.ZipFile

class DebugHookNotInReleaseTest {

    @Test
    fun receiverLivesOnlyInDebugSourceSet() {
        val debugKt = File("src/debug/java/app/openblocker/android/debug/DebugSessionReceiver.kt")
        val mainKt = File("src/main/java/app/openblocker/android/debug/DebugSessionReceiver.kt")
        assertTrue("DebugSessionReceiver must exist in the debug source set", debugKt.isFile)
        assertFalse("DebugSessionReceiver must not exist in main", mainKt.exists())

        val mainManifest = File("src/main/AndroidManifest.xml").readText()
        assertFalse(mainManifest.contains("DebugSessionReceiver"))
        assertFalse(mainManifest.contains("START_SESSION"))

        val debugManifest = File("src/debug/AndroidManifest.xml").readText()
        assertTrue(debugManifest.contains("DebugSessionReceiver"))
        assertTrue(debugManifest.contains("START_SESSION"))
        assertTrue(debugManifest.contains("END_SESSION"))
    }

    @Test
    fun releaseApkDoesNotContainDebugReceiverWhenBuilt() {
        val apk = File("build/outputs/apk/release/app-release.apk")
        if (!apk.isFile) {
            return
        }
        val haystack = ZipFile(apk).use { zip ->
            zip.entries().asSequence()
                .filter { it.name.endsWith(".dex") }
                .joinToString("\n") { entry ->
                    zip.getInputStream(entry).readBytes().toString(Charsets.ISO_8859_1)
                }
        }
        assertFalse(
            "release APK must not contain DebugSessionReceiver",
            haystack.contains("DebugSessionReceiver")
        )
        assertFalse(
            "release APK must not contain START_SESSION action",
            haystack.contains("app.openblocker.android.debug.START_SESSION")
        )
    }

    @Test
    fun debugApkContainsDebugReceiverWhenBuilt() {
        val apk = File("build/outputs/apk/debug/app-debug.apk")
        if (!apk.isFile) {
            return
        }
        val haystack = ZipFile(apk).use { zip ->
            zip.entries().asSequence()
                .filter { it.name.endsWith(".dex") }
                .joinToString("\n") { entry ->
                    zip.getInputStream(entry).readBytes().toString(Charsets.ISO_8859_1)
                }
        }
        assertTrue(
            "debug APK must contain DebugSessionReceiver",
            haystack.contains("DebugSessionReceiver")
        )
        assertTrue(
            "debug APK must contain START_SESSION action",
            haystack.contains("app.openblocker.android.debug.START_SESSION")
        )
    }
}
