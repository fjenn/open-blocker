package app.openblocker.android.util

/**
 * Android stores enabled accessibility services as ComponentName flattened
 * strings, either `pkg/pkg.Class` or `pkg/.Class`. Match both.
 */
object AccessibilityServiceNames {

    fun matches(enabledList: String?, packageName: String, className: String): Boolean {
        if (enabledList.isNullOrBlank()) return false
        val relative = if (className.startsWith("$packageName.")) {
            ".${className.substring(packageName.length + 1)}"
        } else {
            className
        }
        val candidates = setOf(
            "$packageName/$className",
            "$packageName/$relative"
        )
        return enabledList.split(':')
            .map { it.trim() }
            .any { it in candidates }
    }
}
