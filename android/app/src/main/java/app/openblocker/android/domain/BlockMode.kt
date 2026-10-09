package app.openblocker.android.domain

import java.util.UUID

data class BlockMode(
    val id: String = UUID.randomUUID().toString(),
    var name: String,
    var kind: Kind = Kind.BLOCK,
    var packages: Set<String> = emptySet(),
    var websites: List<String> = emptyList(),
    var isDefault: Boolean = false
) {
    enum class Kind(val raw: String) {
        BLOCK("block"),
        ALLOW_ONLY("allowOnly");

        companion object {
            fun fromRaw(raw: String): Kind =
                entries.find { it.raw == raw } ?: BLOCK
        }
    }

    val allowedAppCount: Int get() = if (kind == Kind.ALLOW_ONLY) packages.size else 0
    val blockedAppCount: Int get() = if (kind == Kind.BLOCK) packages.size else 0
    val websiteCount: Int get() = websites.size

    val subtitle: String
        get() {
            val parts = mutableListOf<String>()
            when (kind) {
                Kind.ALLOW_ONLY -> {
                    if (allowedAppCount > 0) {
                        parts += "Allows $allowedAppCount app${if (allowedAppCount == 1) "" else "s"}"
                    } else {
                        parts += "Blocks all apps"
                    }
                }
                Kind.BLOCK -> {
                    if (blockedAppCount > 0) {
                        parts += "Blocks $blockedAppCount app${if (blockedAppCount == 1) "" else "s"}"
                    }
                }
            }
            if (websiteCount > 0) {
                parts += "$websiteCount website${if (websiteCount == 1) "" else "s"}"
            }
            return if (parts.isEmpty()) "Nothing chosen yet" else parts.joinToString(" · ")
        }

    fun pickedSummary(): String {
        if (packages.isEmpty() && websites.isEmpty()) return "None"
        val parts = mutableListOf<String>()
        if (packages.isNotEmpty()) {
            parts += "${packages.size} app${if (packages.size == 1) "" else "s"}"
        }
        if (websites.isNotEmpty()) {
            parts += "${websites.size} site${if (websites.size == 1) "" else "s"}"
        }
        return parts.joinToString(" · ")
    }

    fun shouldBlock(packageName: String, selfPackage: String): Boolean {
        if (packageName == selfPackage) return false
        if (packageName == "com.android.systemui") return false
        return when (kind) {
            Kind.BLOCK -> packages.contains(packageName)
            Kind.ALLOW_ONLY -> !packages.contains(packageName)
        }
    }
}

object ModeName {
    const val placeholder = "e.g. Deep work"

    fun validated(raw: String): String? {
        val trimmed = raw.trim()
        return trimmed.ifEmpty { null }
    }
}

object ModeDefaults {
    val starterTemplate: ModeTemplate = ModeTemplate.DETOX

    fun seeded(modes: List<BlockMode>, activeModeId: String?): Pair<List<BlockMode>, String>? {
        if (modes.isNotEmpty()) return null
        val starter = starterTemplate.makeMode(isDefault = true)
        return listOf(starter) to starter.id
    }
}
