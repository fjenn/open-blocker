package app.openblocker.android.ui

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** In-app toast bus so NFC/QR rejects use the same capsule as the Block tab. */
object AppNotice {
    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message.asStateFlow()

    fun show(text: String) {
        _message.value = text
    }

    fun consume() {
        _message.value = null
    }
}
