package app.openblocker.android

import android.app.Application
import android.content.Context
import app.openblocker.android.data.CountManager

class OpenBlockerApplication : Application() {
    
    companion object {
        private lateinit var instance: OpenBlockerApplication
        
        fun getAppContext(): Context = instance.applicationContext
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        CountManager.retrySendIfPending()
    }
}
