package app.openblocker.android.domain

import java.net.IDN
import java.net.URI
import java.util.Locale

/**
 * Normalizes a typed domain or a browser address-bar string and matches it
 * against a mode's website list. Host only: scheme, port, path, query, and
 * a leading www. are ignored. A listed domain also matches its subdomains.
 */
object DomainMatch {

    fun hostOf(raw: String): String? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return null
        if (trimmed.any { it.isWhitespace() }) return null

        val withoutHash = trimmed.substringBefore('#').substringBefore('?')
        val prepared = when {
            withoutHash.contains("://") -> withoutHash
            withoutHash.startsWith("//") -> "http:$withoutHash"
            else -> "http://$withoutHash"
        }

        val host = try {
            val uri = URI(prepared)
            uri.host?.takeIf { it.isNotBlank() } ?: fallbackHost(withoutHash)
        } catch (_: Exception) {
            fallbackHost(withoutHash)
        } ?: return null

        return normalizeHost(host)
    }

    fun normalizeRule(raw: String): String? = hostOf(raw)

    fun matches(visited: String, listed: String): Boolean {
        val host = hostOf(visited) ?: return false
        val rule = hostOf(listed) ?: return false
        return host == rule || host.endsWith(".$rule")
    }

    fun listedHostMatches(visited: String, listed: Iterable<String>): Boolean {
        return listed.any { matches(visited, it) }
    }

    private fun fallbackHost(raw: String): String? {
        val noScheme = raw.substringAfter("://", raw).trimStart('/')
        val authority = noScheme.substringBefore('/').substringBefore('?')
        val host = authority.substringBeforeLast('@').let { userHost ->
            if (userHost.startsWith("[")) {
                userHost.substringAfter('[').substringBefore(']')
            } else {
                userHost.substringBefore(':')
            }
        }
        return host.takeIf { it.isNotBlank() }
    }

    private fun normalizeHost(host: String): String? {
        var value = host.trim().trim('.').lowercase(Locale.US)
        if (value.isEmpty()) return null
        if (value.startsWith("www.")) value = value.removePrefix("www.")
        value = try {
            IDN.toASCII(value)
        } catch (_: Exception) {
            value
        }
        if (!isPlausibleHost(value)) return null
        return value
    }

    private fun isPlausibleHost(host: String): Boolean {
        if (host.equals("localhost", ignoreCase = true)) return true
        if (host.all { it.isDigit() || it == '.' }) {
            return host.split('.').size == 4 && host.split('.').all { part ->
                part.toIntOrNull()?.let { it in 0..255 } == true
            }
        }
        if (!host.contains('.')) return false
        if (host.any { !it.isLetterOrDigit() && it != '.' && it != '-' }) return false
        val labels = host.split('.')
        if (labels.any { it.isEmpty() || it.startsWith('-') || it.endsWith('-') }) return false
        return labels.last().any { it.isLetter() }
    }
}
