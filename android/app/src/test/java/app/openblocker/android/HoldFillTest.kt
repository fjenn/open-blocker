package app.openblocker.android

import app.openblocker.android.domain.FillLevel
import app.openblocker.android.domain.HoldFill
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HoldFillTest {
    private val frame = 1.0 / 60

    private fun run(fill: HoldFill, seconds: Double): List<HoldFill.Event> {
        val events = mutableListOf<HoldFill.Event>()
        var elapsed = 0.0
        while (elapsed < seconds - 1e-9) {
            events += fill.step(frame)
            elapsed += frame
        }
        return events
    }

    @Test
    fun fullHoldCompletesOnceAtFillDuration() {
        val fill = HoldFill()
        assertTrue(fill.press())
        val early = run(fill, HoldFill.fillDuration - 0.1)
        assertFalse(early.contains(HoldFill.Event.COMPLETED))
        assertTrue(fill.progress < 1)

        val late = mutableListOf<HoldFill.Event>()
        while (!late.contains(HoldFill.Event.COMPLETED) && late.size < 100) {
            late += fill.step(frame)
        }
        assertEquals(1, late.count { it == HoldFill.Event.COMPLETED })
        assertEquals(1.0, fill.progress, 0.0)
        assertFalse(fill.isHolding)

        fill.applyLocked(true)
        assertEquals(emptyList<HoldFill.Event>(), run(fill, 0.5))
        assertEquals(1.0, fill.progress, 0.0)
    }

    @Test
    fun fillIsADeliberateHold() {
        assertTrue(HoldFill.fillDuration >= 3)
        assertTrue(HoldFill.fillDuration <= 8)
        assertTrue(HoldFill.drainDuration < HoldFill.fillDuration)
    }

    @Test
    fun earlyReleaseDrainsWithoutCompleting() {
        val fill = HoldFill()
        fill.press()
        run(fill, HoldFill.fillDuration * 0.5)
        assertTrue(fill.progress > 0.4)
        fill.release()
        val events = run(fill, HoldFill.drainDuration)
        assertFalse(events.contains(HoldFill.Event.COMPLETED))
        assertEquals(0.0, fill.progress, 1e-9)
        assertTrue(fill.isSettled)
    }

    @Test
    fun holdingCannotEndASession() {
        val fill = HoldFill()
        fill.applyLocked(true)
        fill.snapToRest()
        assertEquals(1.0, fill.progress, 0.0)
        assertFalse(fill.press())
        assertEquals(emptyList<HoldFill.Event>(), run(fill, 2.0))
        assertEquals(1.0, fill.progress, 0.0)
    }

    @Test
    fun shaderLevelHidesEmptyAndOvershootsFull() {
        assertEquals(FillLevel.hidden, FillLevel.shaderLevel(0.0), 0f)
        assertTrue(FillLevel.shaderLevel(1.0) > 1f)
        assertTrue(FillLevel.shaderLevel(0.5) < FillLevel.shaderLevel(0.6))
        assertEquals(0.5f, FillLevel.shaderLevel(0.5), 0.02f)
    }
}
