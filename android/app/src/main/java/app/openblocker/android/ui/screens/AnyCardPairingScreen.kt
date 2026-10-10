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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
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
fun AnyCardPairingScreen(onBack: () -> Unit) {
    val pairingMode by PairingStateManager.mode.collectAsState()
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val colors = obColors()

    DisposableEffect(Unit) {
        onDispose { PairingStateManager.clearMode() }
    }

    val pairingState = when (val mode = pairingMode) {
        is PairingStateManager.Mode.AnyCard -> {
            when (mode.step) {
                1 -> PairingState.FirstScan
                2 -> PairingState.SecondScan
                3 -> PairingState.Success
                else -> PairingState.Instructions
            }
        }
        else -> PairingState.Instructions
    }

    Column(Modifier.fillMaxSize().background(colors.canvas).testTag("anycard_screen")) {
        PushedHeader("Pair any card", onBack)
        ScrollColumn {
            when (pairingState) {
                PairingState.Instructions -> {
                    Text("Register any NFC card", style = ObText.title, color = colors.ink, textAlign = TextAlign.Center)
                    Spacer(Modifier.height(Space.s))
                    CardSurface {
                        Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                            Text("Not every card works. Test yours.", style = ObText.body, color = colors.ink)
                            Text(
                                "Transit cards, hotel keys and work badges are worth trying. Registration needs two taps of the same card to confirm the ID is stable.",
                                style = ObText.body,
                                color = colors.inkSecondary
                            )
                        }
                    }
                    Spacer(Modifier.height(Space.s))
                    CardSurface {
                        Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                            Text("Not all cards work", style = ObText.headline, color = colors.danger)
                            Text(
                                "Many bank cards and phone wallets show a new ID on each tap, so they cannot be used. The app rejects any card whose ID changes between taps or falls in the random-ID range.",
                                style = ObText.body,
                                color = colors.inkSecondary
                            )
                        }
                    }
                    Spacer(Modifier.height(Space.m))
                    PrimaryButton("Start pairing", emphasis = ButtonEmphasis.INK, onClick = {
                        PairingStateManager.setMode(PairingStateManager.Mode.AnyCard(null, 1))
                    })
                }
                PairingState.FirstScan, PairingState.SecondScan -> {
                    CardSurface(raised = true) {
                        Column(
                            Modifier.padding(Space.l),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(Space.s)
                        ) {
                            Text(
                                if (pairingState == PairingState.FirstScan) "Tap 1 of 2" else "Tap 2 of 2",
                                style = ObText.title,
                                color = colors.ink
                            )
                            Text(
                                if (pairingState == PairingState.FirstScan) {
                                    "Hold your card near the back of your phone"
                                } else {
                                    "Tap the same card again to confirm"
                                },
                                style = ObText.body,
                                color = colors.inkSecondary,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                    if (errorMessage != null) {
                        Spacer(Modifier.height(Space.s))
                        Text(errorMessage!!, style = ObText.body, color = colors.danger)
                    }
                    Spacer(Modifier.height(Space.m))
                    PrimaryButton("Cancel", onClick = {
                        PairingStateManager.clearMode()
                        errorMessage = null
                    })
                }
                PairingState.Success -> {
                    CardSurface(raised = true) {
                        Column(
                            Modifier.padding(Space.l),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(Space.s)
                        ) {
                            Text("Card paired", style = ObText.title, color = colors.ink)
                            Text(
                                "You can now use this card to start and stop blocking sessions.",
                                style = ObText.body,
                                color = colors.inkSecondary,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                    Spacer(Modifier.height(Space.m))
                    PrimaryButton("Done", emphasis = ButtonEmphasis.INK, onClick = onBack)
                }
            }
        }
    }
}

sealed class PairingState {
    object Instructions : PairingState()
    object FirstScan : PairingState()
    object SecondScan : PairingState()
    object Success : PairingState()
}
