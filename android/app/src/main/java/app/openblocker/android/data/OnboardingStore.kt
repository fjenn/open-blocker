package app.openblocker.android.data

import android.content.Context
import app.openblocker.android.OpenBlockerApplication

object OnboardingStore {
    private val prefs by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences("onboarding_prefs", Context.MODE_PRIVATE)
    }

    fun isComplete(): Boolean = prefs.getBoolean("complete", false)

    fun complete() {
        prefs.edit().putBoolean("complete", true).apply()
    }
}
