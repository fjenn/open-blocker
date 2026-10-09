package app.openblocker.android.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Open Blocker design tokens: warm stone and ink colors.
 * The app is dark by default; Settings > Appearance picks light, dark or system.
 * Brand blue is only for switches and the mark.
 */

// Light theme colors
object LightPalette {
    val canvas = Color(0xFFE8E5E1)
    val chrome = Color(0xFFDCD8D3)
    val sheet = Color(0xFFEFEDEA)
    val surface = Color(0xFFF6F5F2)
    val surfaceRaised = Color(0xFFFFFFFF)
    val fill = Color(0xFFDFDBD6)
    val hairline = Color(0x121B1B1B) // 0x1B1B1B with 0.07 alpha
    val ink = Color(0xFF1B1B1B)
    val inkSecondary = Color(0xFF76716B)
    val inkTertiary = Color(0xFFA7A29C)
    val inkInverse = Color(0xFFFFFFFF)
    val accent = Color(0xFF4450F2)
    val success = Color(0xFF3E6A4C)
    val danger = Color(0xFFB8432F)
    val shadow = Color(0x1A3A3128) // 0x3A3128 with 0.10 alpha
}

// Dark theme colors
object DarkPalette {
    val canvas = Color(0xFF181818)
    val chrome = Color(0xFF0D0D0D)
    val sheet = Color(0xFF1E1E1E)
    val surface = Color(0xFF232323)
    val surfaceRaised = Color(0xFF2D2D2D)
    val fill = Color(0xFF2E2E2E)
    val hairline = Color(0x14FFFFFF) // 0xFFFFFF with 0.08 alpha
    val ink = Color(0xFFF2F0ED)
    val inkSecondary = Color(0xFF9B9893)
    val inkTertiary = Color(0xFF64615D)
    val inkInverse = Color(0xFF161616)
    val accent = Color(0xFF7480FF)
    val success = Color(0xFF7FB08E)
    val danger = Color(0xFFFF7A63)
    val shadow = Color(0x80000000) // 0x000000 with 0.5 alpha
}

/**
 * The 3D key: one warm mid gray in both themes, so it reads on black and on
 * stone alike. Holding fills it with a deeper tone of the same gray; a full
 * key is the locked look.
 */
object KeyPalette {
    val body = Color(0xFF9A9690)
    val fill = Color(0xFF7A7671)
    const val environmentIntensity = 0.7f
}
