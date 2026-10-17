package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
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
    // Prominent disclosure for Google Play's AccessibilityService policy.
    // Separate from any other disclosure, shown before the system settings page,
    // and consent is the explicit "Agree" tap.
    val points = listOf(
        "What it sees: the name of the app that is open, so a blocked app is covered by the block screen.",
        "During a block only: the web address in supported browsers (Chrome, Samsung Internet, Firefox, Brave, Edge, Opera, DuckDuckGo, Vivaldi), so websites on your list are blocked.",
        "How it is used: only to block, only on this phone. Open Blocker does not store, send, or share app names, addresses, or anything else it sees.",
        "What it does: when you open something on your block list, it goes back or home and shows the block screen. It never taps, types, or changes anything else."
    )
    val restrictedNote = "If Android says this setting is restricted, open App info for Open Blocker, tap the menu, choose Allow restricted settings, then try again."
    Column(
        modifier.fillMaxWidth().verticalScroll(rememberScrollState()).background(colors.sheet).padding(horizontal = Space.margin).navigationBarsPadding().padding(bottom = Space.xs).testTag("accessibility_explainer"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Space.m)
    ) {
        Spacer(Modifier.height(Space.s))
        Text("Open Blocker uses Accessibility".asCopy(), style = ObText.title.copy(fontWeight = FontWeight.Medium), color = colors.ink, textAlign = TextAlign.Center)
        Text("Android only lets an app block other apps and websites through the Accessibility service. Here is exactly what Open Blocker does with it.".asCopy(), style = ObText.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Space.s)) {
            points.forEach { Text(("\u2022 " + it).asCopy(), style = ObText.subhead, color = colors.ink) }
            if (restrictedLikely) Text(restrictedNote.asCopy(), style = ObText.footnote, color = colors.inkSecondary)
        }
        PrimaryButton("Agree and open Settings", emphasis = ButtonEmphasis.INK, testTag = "accessibility_agree", onClick = onContinue)
        Text("No thanks".asCopy(), style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary, modifier = Modifier.clickable(onClick = onNotNow).padding(Space.s).testTag("accessibility_decline"))
    }
}
