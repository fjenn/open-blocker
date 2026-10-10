package app.openblocker.android

import app.openblocker.android.domain.HoldHapticCurve
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HoldHapticCurveTest {

    @Test
    fun buildUpStartsSoftAndRisesSteadily() {
        val steps = generateSequence(0.0) { it + 0.05 }.takeWhile { it <= 1.0001 }.toList()
        val intensity = steps.map { HoldHapticCurve.intensity(it) }
        val sharpness = steps.map { HoldHapticCurve.sharpness(it) }
        assertTrue(intensity.first() < 0.3)
        assertTrue(intensity.last() > 0.9)
        assertEquals(intensity, intensity.sorted())
        assertEquals(sharpness, sharpness.sorted())
        assertTrue(intensity.all { it in 0.0..1.0 })
        assertTrue(sharpness.all { it in -1.0..1.0 })
    }

    @Test
    fun tapsSpeedUpOverTheHold() {
        val taps = HoldHapticCurve.tapProgress
        assertEquals(21, taps.size)
        assertEquals(0.12, HoldHapticCurve.tapTimes.first(), 0.0)
        assertEquals(4.94, HoldHapticCurve.tapTimes.last(), 0.0)
        assertTrue(taps.all { it in 0.0..0.999999 })
        val gaps = taps.zipWithNext { a, b -> b - a }
        assertEquals(gaps, gaps.sortedDescending())
        assertTrue(gaps.first() / gaps.last() > 4)
    }
}
