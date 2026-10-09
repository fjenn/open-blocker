package app.openblocker.android.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Open Blocker typography scale. Every text style used by the UI.
 * Scales with the system font size (accessibility).
 */
object OpenBlockerTextStyle {
    val timer = TextStyle(
        fontSize = 44.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-1.0).sp
    )
    
    val largeTitle = TextStyle(
        fontSize = 40.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-1.0).sp
    )
    
    val title = TextStyle(
        fontSize = 24.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.4).sp
    )
    
    val headline = TextStyle(
        fontSize = 16.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.1).sp
    )
    
    val body = TextStyle(
        fontSize = 15.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    
    val button = TextStyle(
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.sp
    )
    
    val subhead = TextStyle(
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    
    val footnote = TextStyle(
        fontSize = 12.sp,
        fontWeight = FontWeight.Medium,
        letterSpacing = 0.sp
    )
    
    val caption = TextStyle(
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.6.sp
    )
}

// Material3 Typography for compatibility
val Typography = Typography(
    displayLarge = OpenBlockerTextStyle.largeTitle,
    displayMedium = OpenBlockerTextStyle.title,
    displaySmall = OpenBlockerTextStyle.headline,
    headlineLarge = OpenBlockerTextStyle.largeTitle,
    headlineMedium = OpenBlockerTextStyle.title,
    headlineSmall = OpenBlockerTextStyle.headline,
    titleLarge = OpenBlockerTextStyle.title,
    titleMedium = OpenBlockerTextStyle.headline,
    titleSmall = OpenBlockerTextStyle.subhead,
    bodyLarge = OpenBlockerTextStyle.body,
    bodyMedium = OpenBlockerTextStyle.body,
    bodySmall = OpenBlockerTextStyle.subhead,
    labelLarge = OpenBlockerTextStyle.button,
    labelMedium = OpenBlockerTextStyle.footnote,
    labelSmall = OpenBlockerTextStyle.caption
)
