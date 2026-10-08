package app.openblocker.android.ui.screens

import org.junit.Assert.*
import org.junit.Test

class LaunchableAppsTest {

    @Test
    fun listsLaunchableThirdPartyAndSystemApps() {
        assertTrue(
            LaunchableApps.shouldList("com.android.chrome", hasLauncherIcon = true, selfPackage = "app.openblocker.android")
        )
        assertTrue(
            LaunchableApps.shouldList("com.google.android.calculator", hasLauncherIcon = true, selfPackage = "app.openblocker.android")
        )
        assertTrue(
            LaunchableApps.shouldList("com.google.android.deskclock", hasLauncherIcon = true, selfPackage = "app.openblocker.android")
        )
        assertTrue(
            LaunchableApps.shouldList("com.android.settings", hasLauncherIcon = true, selfPackage = "app.openblocker.android")
        )
    }

    @Test
    fun hidesSelfAndAppsWithoutLauncher() {
        assertFalse(
            LaunchableApps.shouldList("app.openblocker.android", hasLauncherIcon = true, selfPackage = "app.openblocker.android")
        )
        assertFalse(
            LaunchableApps.shouldList("com.android.systemui", hasLauncherIcon = false, selfPackage = "app.openblocker.android")
        )
    }
}
