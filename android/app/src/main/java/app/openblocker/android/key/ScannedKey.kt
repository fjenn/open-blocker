package app.openblocker.android.key

sealed class ScannedKey {
    data class Qr(val payload: String) : ScannedKey()
    data class OpenBlockerTag(val tagIdHex: String) : ScannedKey()
    data class Uid(val uidHex: String) : ScannedKey()
}
