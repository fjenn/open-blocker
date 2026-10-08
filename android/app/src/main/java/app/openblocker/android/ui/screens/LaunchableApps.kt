package app.openblocker.android.ui.screens

object LaunchableApps {

    fun shouldList(packageName: String, hasLauncherIcon: Boolean, selfPackage: String): Boolean {
        return hasLauncherIcon && packageName != selfPackage
    }
}
