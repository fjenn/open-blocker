package app.openblocker.android.util

import org.junit.Assert.*
import org.junit.Test

class AccessibilityServiceNamesTest {

    private val pkg = "app.openblocker.android"
    private val cls = "app.openblocker.android.service.AppBlockingService"

    @Test
    fun matchesFlattenedComponentName() {
        assertTrue(
            AccessibilityServiceNames.matches(
                "$pkg/$cls",
                pkg,
                cls
            )
        )
    }

    @Test
    fun matchesShortClassName() {
        assertTrue(
            AccessibilityServiceNames.matches(
                "$pkg/.service.AppBlockingService",
                pkg,
                cls
            )
        )
    }

    @Test
    fun matchesAmongColonSeparatedList() {
        val list = "com.other/.Svc:$pkg/.service.AppBlockingService:com.foo/.Bar"
        assertTrue(AccessibilityServiceNames.matches(list, pkg, cls))
    }

    @Test
    fun rejectsNullEmptyAndOtherServices() {
        assertFalse(AccessibilityServiceNames.matches(null, pkg, cls))
        assertFalse(AccessibilityServiceNames.matches("", pkg, cls))
        assertFalse(AccessibilityServiceNames.matches("com.other/.Svc", pkg, cls))
    }
}
