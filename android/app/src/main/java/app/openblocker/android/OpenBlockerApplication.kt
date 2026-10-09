package app.openblocker.android

import android.app.Application
import android.content.Context
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.EmergencyUnblockManager
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.ScheduleRepository

class OpenBlockerApplication : Application() {

    companion object {
        private lateinit var instance: OpenBlockerApplication

        fun getAppContext(): Context = instance.applicationContext
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        EmergencyUnblockManager.renewIfDue()
        ModeRepository.seedIfNeeded()
        ScheduleRepository.tick()
        CountManager.retrySendIfPending()
    }
}
