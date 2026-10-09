package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.IconTile
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.permissions.PermissionCopy
import app.openblocker.android.ui.permissions.PermissionCopyCatalog
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors
import androidx.compose.ui.unit.dp

@Composable
fun PermissionDeniedSheet(
    kind: PermissionKind,
    onOpenSettings: () -> Unit,
    onNotNow: () -> Unit,
    modifier: Modifier = Modifier
) {
    PermissionDeniedSheetContent(PermissionCopyCatalog.of(kind), onOpenSettings, onNotNow, modifier)
}

@Composable
fun PermissionDeniedSheetContent(
    copy: PermissionCopy,
    onOpenSettings: () -> Unit,
    onNotNow: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    Column(
        modifier
            .fillMaxWidth()
            .background(colors.sheet)
            .padding(horizontal = Space.margin)
            .padding(bottom = Space.xs)
            .testTag("permission_sheet"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Space.m)
    ) {
        Spacer(Modifier.height(Space.xl))
        IconTile(copy.glyph, size = 56.dp)
        Text(copy.deniedTitle.asCopy(), style = ObText.title.copy(fontWeight = FontWeight.Medium), color = colors.ink, textAlign = TextAlign.Center)
        Text(copy.deniedMessage.asCopy(), style = ObText.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(Space.s))
        PrimaryButton("Open Settings", emphasis = ButtonEmphasis.INK, testTag = "permission_open_settings", onClick = onOpenSettings)
        Text(
            "Not now".asCopy(),
            style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold),
            color = colors.inkSecondary,
            modifier = Modifier
                .clickable(onClick = onNotNow)
                .padding(Space.s)
                .testTag("permission_not_now")
        )
    }
}

@Composable
fun AccessibilityExplainer(
    restrictedLikely: Boolean,
    onContinue: () -> Unit,
    onNotNow: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val body = if (restrictedLikely) {
        "Android requires Accessibility so we can block apps. We don't read your screen or track usage. On Android 13 and later, first allow restricted settings for this app, then turn on Open Blocker in Accessibility."
    } else {
        "Android requires Accessibility so we can block apps. We don't read your screen or track usage. You'll jump to the Accessibility page. Turn on Open Blocker there."
    }
    Column(
        modifier.fillMaxWidth().background(colors.sheet).padding(horizontal = Space.margin).padding(bottom = Space.xs).testTag("accessibility_explainer"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Space.m)
    ) {
        Spacer(Modifier.height(Space.xl))
        IconTile(Glyph.Hourglass, size = 56.dp)
        Text("Allow Accessibility".asCopy(), style = ObText.title.copy(fontWeight = FontWeight.Medium), color = colors.ink)
        Text(body.asCopy(), style = ObText.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
        PrimaryButton("Open Settings", emphasis = ButtonEmphasis.INK, onClick = onContinue)
        Text("Not now".asCopy(), style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary, modifier = Modifier.clickable(onClick = onNotNow).padding(Space.s))
    }
}
