package app.openblocker.android.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/** Paparazzi's layoutlib drops Unicode whitespace; screenshots use braille blank. */
val LocalScreenshotCopy = staticCompositionLocalOf { false }

@Composable
fun String.asCopy(): String = if (LocalScreenshotCopy.current) replace(' ', '\u2800') else this

enum class AppAppearance(val id: String, val title: String) {
    LIGHT("light", "Light"),
    DARK("dark", "Dark"),
    SYSTEM("system", "System");

    companion object {
        const val STORAGE_KEY = "appearance"
        val DEFAULT = DARK

        fun fromId(id: String?): AppAppearance = entries.find { it.id == id } ?: DEFAULT
    }
}

private fun lightScheme() = lightColorScheme(
    primary = LightPalette.accent,
    onPrimary = Color.White,
    background = LightPalette.canvas,
    onBackground = LightPalette.ink,
    surface = LightPalette.surface,
    onSurface = LightPalette.ink,
    surfaceVariant = LightPalette.sheet,
    onSurfaceVariant = LightPalette.inkSecondary,
    outline = LightPalette.hairline,
    error = LightPalette.danger,
    onError = Color.White
)

private fun darkScheme() = darkColorScheme(
    primary = DarkPalette.accent,
    onPrimary = Color.Black,
    background = DarkPalette.canvas,
    onBackground = DarkPalette.ink,
    surface = DarkPalette.surface,
    onSurface = DarkPalette.ink,
    surfaceVariant = DarkPalette.sheet,
    onSurfaceVariant = DarkPalette.inkSecondary,
    outline = DarkPalette.hairline,
    error = DarkPalette.danger,
    onError = Color.Black
)

@Composable
fun OpenBlockerTheme(
    appearance: AppAppearance = AppAppearance.DEFAULT,
    content: @Composable () -> Unit
) {
    val isDark = when (appearance) {
        AppAppearance.LIGHT -> false
        AppAppearance.DARK -> true
        AppAppearance.SYSTEM -> isSystemInDarkTheme()
    }
    val colors = obColors(isDark)
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val parent = view.context
            if (parent is Activity) {
                val window = parent.window
                window.statusBarColor = Color.Transparent.toArgb()
                window.navigationBarColor = colors.chrome.toArgb()
                WindowCompat.getInsetsController(window, view).apply {
                    isAppearanceLightStatusBars = !isDark
                    isAppearanceLightNavigationBars = !isDark
                }
            }
        }
    }
    CompositionLocalProvider(
        LocalObColors provides colors,
        LocalDarkTheme provides isDark
    ) {
        MaterialTheme(
            colorScheme = if (isDark) darkScheme() else lightScheme(),
            typography = Typography,
            content = content
        )
    }
}

@Composable
fun obColors(): ObColors = LocalObColors.current
