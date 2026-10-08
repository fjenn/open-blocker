package app.openblocker.android.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object PairingStateManager {
    
    sealed class Mode {
        object None : Mode()
        object WriteTag : Mode()
        object PairByUid : Mode()
        data class AnyCard(val firstUid: String? = null, val step: Int = 1) : Mode()
    }
    
    private val _mode = MutableStateFlow<Mode>(Mode.None)
    val mode: StateFlow<Mode> = _mode.asStateFlow()
    
    fun setMode(mode: Mode) {
        _mode.value = mode
    }
    
    fun clearMode() {
        _mode.value = Mode.None
    }
}
