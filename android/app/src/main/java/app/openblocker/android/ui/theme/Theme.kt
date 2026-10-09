package app.openblocker.android.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private fun lightColorScheme(): ColorScheme = lightColorScheme(
    primary = LightPalette.accent,
    onPrimary = Color.White,
    primaryContainer = LightPalette.surface,
    onPrimaryContainer = LightPalette.ink,
    secondary = LightPalette.inkSecondary,
    onSecondary = Color.White,
    secondaryContainer = LightPalette.fill,
    onSecondaryContainer = LightPalette.ink,
    tertiary = LightPalette.inkTertiary,
    onTertiary = Color.White,
    tertiaryContainer = LightPalette.sheet,
    onTertiaryContainer = LightPalette.ink,
    error = LightPalette.danger,
    onError = Color.White,
    errorContainer = LightPalette.danger.copy(alpha = 0.1f),
    onErrorContainer = LightPalette.danger,
    background = LightPalette.canvas,
    onBackground = LightPalette.ink,
    surface = LightPalette.surface,
    onSurface = LightPalette.ink,
    surfaceVariant = LightPalette.sheet,
    onSurfaceVariant = LightPalette.inkSecondary,
    outline = LightPalette.hairline,
    outlineVariant = LightPalette.fill,
    scrim = LightPalette.shadow,
    inverseSurface = DarkPalette.surface,
    inverseOnSurface = DarkPalette.ink,
    inversePrimary = DarkPalette.accent,
    surfaceTint = LightPalette.accent
)

private fun darkColorScheme(): ColorScheme = darkColorScheme(
    primary = DarkPalette.accent,
    onPrimary = Color.Black,
    primaryContainer = DarkPalette.surface,
    onPrimaryContainer = DarkPalette.ink,
    secondary = DarkPalette.inkSecondary,
    onSecondary = Color.Black,
    secondaryContainer = DarkPalette.fill,
    onSecondaryContainer = DarkPalette.ink,
    tertiary = DarkPalette.inkTertiary,
    onTertiary = Color.Black,
    tertiaryContainer = DarkPalette.sheet,
    onTertiaryContainer = DarkPalette.ink,
    error = DarkPalette.danger,
    onError = Color.Black,
    errorContainer = DarkPalette.danger.copy(alpha = 0.1f),
    onErrorContainer = DarkPalette.danger,
    background = DarkPalette.canvas,
    onBackground = DarkPalette.ink,
    surface = DarkPalette.surface,
    onSurface = DarkPalette.ink,
    surfaceVariant = DarkPalette.sheet,
    onSurfaceVariant = DarkPalette.inkSecondary,
    outline = DarkPalette.hairline,
    outlineVariant = DarkPalette.fill,
    scrim = DarkPalette.shadow,
    inverseSurface = LightPalette.surface,
    inverseOnSurface = LightPalette.ink,
    inversePrimary = LightPalette.accent,
    surfaceTint = DarkPalette.accent
)

/**
 * The app's appearance mode, chosen in Settings.
 * Dark is the default look.
 */
enum class AppAppearance(val id: String, val title: String) {
    LIGHT("light", "Light"),
    DARK("dark", "Dark"),
    SYSTEM("system", "System");
    
    companion object {
        const val STORAGE_KEY = "appearance"
        val DEFAULT = DARK
        
        fun fromId(id: String?): AppAppearance =
            entries.find { it.id == id } ?: DEFAULT
    }
}

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
    
    val colorScheme = when {
        isDark -> darkColorScheme()
        else -> lightColorScheme()
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !isDark
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

/**
 * Extended color properties for the semantic palette.
 * Use these for design-system-specific colors not covered by Material3.
 */
object OpenBlockerColors {
    @Composable
    fun canvas(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.canvas else LightPalette.canvas
    
    @Composable
    fun chrome(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.chrome else LightPalette.chrome
    
    @Composable
    fun sheet(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.sheet else LightPalette.sheet
    
    @Composable
    fun surfaceRaised(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.surfaceRaised else LightPalette.surfaceRaised
    
    @Composable
    fun fillQuiet(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.fill else LightPalette.fill
    
    @Composable
    fun hairline(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.hairline else LightPalette.hairline
    
    @Composable
    fun inkInverse(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.inkInverse else LightPalette.inkInverse
    
    @Composable
    fun success(isDark: Boolean = isSystemInDarkTheme()) =
        if (isDark) DarkPalette.success else LightPalette.success
}
