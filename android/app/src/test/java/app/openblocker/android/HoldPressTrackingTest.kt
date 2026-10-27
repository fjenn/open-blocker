package app.openblocker.android

import app.openblocker.android.domain.HoldPressTracking
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HoldPressTrackingTest {
    private val width = 200f
    private val height = 80f
    private val tolerance = HoldPressTracking.EXIT_TOLERANCE_DP

    @Test
    fun fingerCanDriftInsideAndStillCountAsHolding() {
        assertTrue(HoldPressTracking.isInsideHoldArea(100f, 40f, width, height, tolerance))
        assertTrue(HoldPressTracking.isInsideHoldArea(20f, 18f, width, height, tolerance))
        assertTrue(
            HoldPressTracking.isInsideHoldArea(210f, 50f, width, height, tolerance)
        )
    }

    @Test
    fun leavingTheAreaCancels() {
        assertFalse(HoldPressTracking.isInsideHoldArea(280f, 40f, width, height, tolerance))
        assertFalse(HoldPressTracking.isInsideHoldArea(100f, -80f, width, height, tolerance))
    }

    @Test
    fun unknownBoundsStayHolding() {
        assertTrue(HoldPressTracking.isInsideHoldArea(900f, 900f, 0f, 0f, tolerance))
    }

    @Test
    fun shortPressWithTinyMoveIsATap() {
        assertTrue(HoldPressTracking.isShortTap(120, 8f, HoldPressTracking.TAP_MOVE_LIMIT_DP))
        assertFalse(HoldPressTracking.isShortTap(120, 40f, HoldPressTracking.TAP_MOVE_LIMIT_DP))
        assertFalse(HoldPressTracking.isShortTap(400, 4f, HoldPressTracking.TAP_MOVE_LIMIT_DP))
    }

    @Test
    fun twelvePointMoveDoesNotLeaveAKey() {
        assertTrue(
            HoldPressTracking.isInsideHoldArea(152f, 152f, 280f, 280f, tolerance)
        )
    }
}
