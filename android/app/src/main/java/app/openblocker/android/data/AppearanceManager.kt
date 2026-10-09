package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import app.openblocker.android.OpenBlockerApplication
import app.openblocker.android.ui.theme.AppAppearance

/**
 * Manages the app's appearance (Light/Dark/System).
 * Dark is the default.
 */
object AppearanceManager {
    
    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences("appearance_prefs", Context.MODE_PRIVATE)
    }
    
    private val _appearance = mutableStateOf(loadAppearance())
    val appearance: State<AppAppearance> = _appearance
    
    private fun loadAppearance(): AppAppearance {
        val id = prefs.getString(AppAppearance.STORAGE_KEY, null)
        return AppAppearance.fromId(id)
    }
    
    fun setAppearance(appearance: AppAppearance) {
        prefs.edit().putString(AppAppearance.STORAGE_KEY, appearance.id).apply()
        _appearance.value = appearance
    }
}
