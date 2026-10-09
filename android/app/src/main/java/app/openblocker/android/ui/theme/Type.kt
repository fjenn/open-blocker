package app.openblocker.android.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.openblocker.android.R

private val Rounded = FontFamily(
    Font(R.font.app_sans_regular, FontWeight.Normal),
    Font(R.font.app_sans_regular, FontWeight.Medium),
    Font(R.font.app_sans_bold, FontWeight.SemiBold),
    Font(R.font.app_sans_bold, FontWeight.Bold)
)

object ObText {
    val timer = TextStyle(
        fontFamily = Rounded,
        fontSize = 44.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp,
        fontFeatureSettings = "tnum"
    )
    val largeTitle = TextStyle(
        fontFamily = Rounded,
        fontSize = 40.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp
    )
    val title = TextStyle(
        fontFamily = Rounded,
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp
    )
    val headline = TextStyle(
        fontFamily = Rounded,
        fontSize = 16.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp
    )
    val body = TextStyle(
        fontFamily = Rounded,
        fontSize = 15.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    val button = TextStyle(
        fontFamily = Rounded,
        fontSize = 15.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp
    )
    val subhead = TextStyle(
        fontFamily = Rounded,
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    val footnote = TextStyle(
        fontFamily = Rounded,
        fontSize = 12.sp,
        fontWeight = FontWeight.Normal,
        letterSpacing = 0.sp
    )
    val caption = TextStyle(
        fontFamily = Rounded,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp
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
