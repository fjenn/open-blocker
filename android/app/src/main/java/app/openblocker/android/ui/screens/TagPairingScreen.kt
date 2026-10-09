package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import app.openblocker.android.data.PairingStateManager
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.PushedHeader
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors

@Composable
fun TagPairingScreen(
    onBack: () -> Unit,
    onNavigateToAnyCard: () -> Unit
) {
    val pairingMode by PairingStateManager.mode.collectAsState()
    val colors = obColors()

    DisposableEffect(Unit) {
        onDispose {
            if (pairingMode != PairingStateManager.Mode.None) {
                PairingStateManager.clearMode()
            }
        }
    }

    Column(Modifier.fillMaxSize().background(colors.canvas)) {
        PushedHeader("Pair NFC tag", onBack)
        ScrollColumn {
            Text(
                "Choose how to pair your NFC tag",
                style = ObText.title,
                color = colors.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = Space.m)
            )
            CardSurface {
                Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                    Text("Write Open Blocker format", style = ObText.headline, color = colors.ink)
                    Text(
                        "Write the Open Blocker tag format to a new or existing NFC tag. This is the recommended method.",
                        style = ObText.body,
                        color = colors.inkSecondary
                    )
                    PrimaryButton("Write tag", emphasis = ButtonEmphasis.INK, onClick = {
                        PairingStateManager.setMode(PairingStateManager.Mode.WriteTag)
                    })
                }
            }
            Spacer(Modifier.height(Space.s))
            CardSurface {
                Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                    Text("Pair by UID", style = ObText.headline, color = colors.ink)
                    Text(
                        "Use an existing tag without modifying it. The app recognizes it by its hardware UID. Transit cards, hotel keys and work badges are worth trying.",
                        style = ObText.body,
                        color = colors.inkSecondary
                    )
                    PrimaryButton("Pair by UID", onClick = {
                        PairingStateManager.setMode(PairingStateManager.Mode.PairByUid)
                    })
                    PrimaryButton("Pair any card", onClick = onNavigateToAnyCard)
                }
            }
            if (pairingMode != PairingStateManager.Mode.None) {
                Spacer(Modifier.height(Space.s))
                CardSurface(raised = true) {
                    Column(
                        Modifier.padding(Space.l),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(Space.s)
                    ) {
                        Text(
                            text = when (pairingMode) {
                                is PairingStateManager.Mode.WriteTag -> "Ready to write tag"
                                is PairingStateManager.Mode.PairByUid -> "Ready to pair tag by UID"
                                else -> ""
                            },
                            style = ObText.headline,
                            color = colors.ink,
                            textAlign = TextAlign.Center
                        )
                        Text(
                            "Hold your NFC tag near the back of your phone",
                            style = ObText.body,
                            color = colors.inkSecondary,
                            textAlign = TextAlign.Center
                        )
                        PrimaryButton("Cancel", onClick = { PairingStateManager.clearMode() })
                    }
                }
            }
            Spacer(Modifier.height(Space.m))
            Text(
                "NFC must be on in your phone settings.",
                style = ObText.footnote,
                color = colors.inkTertiary,
                textAlign = TextAlign.Center
            )
        }
    }
}
