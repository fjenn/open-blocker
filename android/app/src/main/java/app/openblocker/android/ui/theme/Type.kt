package app.openblocker.android.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.openblocker.android.R

/** Inter (OFL) — closest widely-licensed match to SF Pro. */
private val Inter = FontFamily(
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_semibold, FontWeight.SemiBold),
    Font(R.font.inter_bold, FontWeight.Bold)
)

object ObText {
    val timer = TextStyle(
        fontFamily = Inter,
        fontSize = 44.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-1).sp,
        fontFeatureSettings = "tnum"
    )
    val largeTitle = TextStyle(
        fontFamily = Inter,
        fontSize = 40.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-1).sp
    )
    val title = TextStyle(
        fontFamily = Inter,
        fontSize = 24.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.4).sp
    )
    val headline = TextStyle(
        fontFamily = Inter,
        fontSize = 16.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.1).sp
    )
    val body = TextStyle(
        fontFamily = Inter,
        fontSize = 15.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    val button = TextStyle(
        fontFamily = Inter,
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.sp
    )
    val subhead = TextStyle(
        fontFamily = Inter,
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    val footnote = TextStyle(
        fontFamily = Inter,
        fontSize = 12.sp,
        fontWeight = FontWeight.Medium,
        letterSpacing = 0.sp
    )
    val caption = TextStyle(
        fontFamily = Inter,
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.6.sp
    )
}

val Typography = Typography(
    displayLarge = ObText.largeTitle,
    headlineLarge = ObText.largeTitle,
    headlineMedium = ObText.title,
    headlineSmall = ObText.headline,
    titleLarge = ObText.title,
    titleMedium = ObText.headline,
    titleSmall = ObText.subhead,
    bodyLarge = ObText.body,
    bodyMedium = ObText.body,
    bodySmall = ObText.subhead,
    labelLarge = ObText.button,
    labelMedium = ObText.footnote,
    labelSmall = ObText.caption
)
