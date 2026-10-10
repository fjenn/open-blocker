package app.openblocker.android.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

object LightPalette {
    val canvas = Color(0xFFE8E5E1)
    val chrome = Color(0xFFDCD8D3)
    val sheet = Color(0xFFEFEDEA)
    val surface = Color(0xFFF6F5F2)
    val surfaceRaised = Color(0xFFFFFFFF)
    val fill = Color(0xFFDFDBD6)
    val hairline = Color(0x121B1B1B)
    val ink = Color(0xFF1B1B1B)
    val inkSecondary = Color(0xFF76716B)
    val inkTertiary = Color(0xFFA7A29C)
    val inkInverse = Color(0xFFFFFFFF)
    val accent = Color(0xFF4450F2)
    val success = Color(0xFF3E6A4C)
    val danger = Color(0xFFB8432F)
    val shadow = Color(0x1A3A3128)
}

object DarkPalette {
    val canvas = Color(0xFF181818)
    val chrome = Color(0xFF0D0D0D)
    val sheet = Color(0xFF1E1E1E)
    val surface = Color(0xFF232323)
    val surfaceRaised = Color(0xFF2D2D2D)
    val fill = Color(0xFF2E2E2E)
    val hairline = Color(0x14FFFFFF)
    val ink = Color(0xFFF2F0ED)
    val inkSecondary = Color(0xFF9B9893)
    val inkTertiary = Color(0xFF64615D)
    val inkInverse = Color(0xFF161616)
    val accent = Color(0xFF7480FF)
    val success = Color(0xFF7FB08E)
    val danger = Color(0xFFFF7A63)
    val shadow = Color(0x80000000)
}

object KeyPalette {
    val body = Color(0xFF9A9690)
    val fill = Color(0xFF7A7671)
    const val environmentIntensity = 0.7f
}

@Immutable
data class ObColors(
    val canvas: Color,
    val chrome: Color,
    val sheet: Color,
    val surface: Color,
    val surfaceRaised: Color,
    val fillQuiet: Color,
    val hairline: Color,
    val ink: Color,
    val inkSecondary: Color,
    val inkTertiary: Color,
    val inkInverse: Color,
    val accent: Color,
    val success: Color,
    val danger: Color,
    val shadow: Color,
    val isDark: Boolean
)

fun obColors(isDark: Boolean): ObColors {
    val p = if (isDark) DarkPalette else LightPalette
    return ObColors(
        canvas = if (isDark) DarkPalette.canvas else LightPalette.canvas,
        chrome = if (isDark) DarkPalette.chrome else LightPalette.chrome,
        sheet = if (isDark) DarkPalette.sheet else LightPalette.sheet,
        surface = if (isDark) DarkPalette.surface else LightPalette.surface,
        surfaceRaised = if (isDark) DarkPalette.surfaceRaised else LightPalette.surfaceRaised,
        fillQuiet = if (isDark) DarkPalette.fill else LightPalette.fill,
        hairline = if (isDark) DarkPalette.hairline else LightPalette.hairline,
        ink = if (isDark) DarkPalette.ink else LightPalette.ink,
        inkSecondary = if (isDark) DarkPalette.inkSecondary else LightPalette.inkSecondary,
        inkTertiary = if (isDark) DarkPalette.inkTertiary else LightPalette.inkTertiary,
        inkInverse = if (isDark) DarkPalette.inkInverse else LightPalette.inkInverse,
        accent = if (isDark) DarkPalette.accent else LightPalette.accent,
        success = if (isDark) DarkPalette.success else LightPalette.success,
        danger = if (isDark) DarkPalette.danger else LightPalette.danger,
        shadow = if (isDark) DarkPalette.shadow else LightPalette.shadow,
        isDark = isDark
    )
}

val LocalObColors = staticCompositionLocalOf { obColors(isDark = true) }
val LocalDarkTheme = staticCompositionLocalOf { true }
