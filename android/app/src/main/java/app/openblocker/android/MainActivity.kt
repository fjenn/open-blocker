package app.openblocker.android

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.data.EmergencyUnblockManager
import app.openblocker.android.data.PairingStateManager
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.ScheduleRepository
import app.openblocker.android.nfc.NfcDispatch
import app.openblocker.android.nfc.NfcHandler
import app.openblocker.android.nfc.UidValidator
import app.openblocker.android.ui.navigation.AppNavigation
import app.openblocker.android.ui.theme.OpenBlockerTheme
import app.openblocker.android.ui.theme.obColors

class MainActivity : ComponentActivity() {

    private var nfcAdapter: NfcAdapter? = null
    private val nfcHandler = NfcHandler()

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        EmergencyUnblockManager.renewIfDue()

        setContent {
            val appearance by AppearanceManager.appearance
            OpenBlockerTheme(appearance = appearance) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .semantics { testTagsAsResourceId = true },
                    color = obColors().canvas
                ) {
                    AppNavigation()
                }
            }
        }

        handleNfcIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        EmergencyUnblockManager.renewIfDue()
        ScheduleRepository.tick()
        NfcDispatch.enable(this, nfcAdapter)
    }

    override fun onPause() {
        super.onPause()
        NfcDispatch.disable(this, nfcAdapter)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNfcIntent(intent)
    }

    private fun handleNfcIntent(intent: Intent?) {
        val tag = NfcDispatch.tagFrom(intent) ?: return
        handleTagBasedOnMode(tag)
    }

    private fun handleTagBasedOnMode(tag: Tag) {
        when (val mode = PairingStateManager.mode.value) {
            is PairingStateManager.Mode.None -> {
                nfcHandler.handleTag(this, tag)
            }
            is PairingStateManager.Mode.WriteTag -> {
                val success = nfcHandler.writeTag(tag, "app.openblocker.android")
                if (success) {
                    Toast.makeText(this, "Tag written and paired successfully", Toast.LENGTH_SHORT).show()
                    PairingStateManager.clearMode()
                } else {
                    Toast.makeText(this, "Failed to write tag. Make sure it is writable.", Toast.LENGTH_LONG).show()
                }
            }
            is PairingStateManager.Mode.PairByUid -> {
                val success = nfcHandler.pairByUid(tag)
                if (success) {
                    Toast.makeText(this, "Tag paired by UID successfully", Toast.LENGTH_SHORT).show()
                    PairingStateManager.clearMode()
                } else {
                    Toast.makeText(this, "Failed to pair tag", Toast.LENGTH_SHORT).show()
                }
            }
            is PairingStateManager.Mode.AnyCard -> {
                val uid = tag.id
                if (uid == null) {
                    Toast.makeText(this, "Could not read card ID", Toast.LENGTH_SHORT).show()
                    return
                }
                val validationError = UidValidator.validateUid(uid)
                if (validationError != null) {
                    Toast.makeText(this, validationError, Toast.LENGTH_LONG).show()
                    PairingStateManager.clearMode()
                    return
                }
                val uidString = UidValidator.formatUid(uid)
                if (mode.step == 1) {
                    PairingStateManager.setMode(PairingStateManager.Mode.AnyCard(uidString, 2))
                    Toast.makeText(this, "Scan 1 of 2 recorded. Tap the same card again.", Toast.LENGTH_SHORT).show()
                } else if (mode.step == 2) {
                    val firstUid = mode.firstUid
                    if (firstUid != null && uidString == firstUid) {
                        PreferencesManager.addAnyCardUid(uidString)
                        PairingStateManager.setMode(PairingStateManager.Mode.AnyCard(uidString, 3))
                        Toast.makeText(this, "Card paired successfully!", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(this, "Card IDs don't match. This card may generate random IDs.", Toast.LENGTH_LONG).show()
                        PairingStateManager.clearMode()
                    }
                }
            }
        }
    }
}
