package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.openblocker.android.domain.DomainMatch
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.ScheduleRepository
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.ModeName
import app.openblocker.android.domain.ModeTemplate
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.HairlineDivider
import app.openblocker.android.ui.components.IconTile
import app.openblocker.android.ui.components.InfoNote
import app.openblocker.android.ui.components.ModeTemplateGlyph
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.components.SegmentedPill
import app.openblocker.android.ui.components.SettingsGroup
import app.openblocker.android.ui.components.SettingsRow
import app.openblocker.android.ui.components.SettingsToggleRow
import app.openblocker.android.ui.components.SheetHeader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors

@Composable
fun ModesSheet(
    onClose: () -> Unit,
    onNew: () -> Unit,
    onEdit: (BlockMode) -> Unit
) {
    val modes by ModeRepository.modes.collectAsState()
    val activeId by ModeRepository.activeModeId.collectAsState()
    ModesSheetContent(
        modes = modes,
        activeId = activeId,
        onClose = onClose,
        onNew = onNew,
        onSelect = { ModeRepository.setActive(it) },
        onEdit = onEdit
    )
}

@Composable
fun ModesSheetContent(
    modes: List<BlockMode>,
    activeId: String?,
    onClose: () -> Unit,
    onNew: () -> Unit,
    onSelect: (BlockMode) -> Unit,
    onEdit: (BlockMode) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    Column(modifier.fillMaxSize().background(colors.sheet).testTag("modes_sheet")) {
        SheetHeader("Select mode", onClose, onLeading = onNew, leadingGlyph = Glyph.Plus)
        ScrollColumn {
            modes.forEach { mode ->
                ModeCard(mode, mode.id == activeId, { onSelect(mode) }, { onEdit(mode) })
                Spacer(Modifier.height(Space.s))
            }
            Spacer(Modifier.height(Space.s))
            PrimaryButton("Done", emphasis = ButtonEmphasis.INK, onClick = onClose)
            Spacer(Modifier.height(Space.l))
        }
    }
}

@Composable
private fun ModeCard(mode: BlockMode, active: Boolean, onSelect: () -> Unit, onEdit: () -> Unit) {
    val colors = obColors()
    CardSurface(raised = active, modifier = Modifier.clickable(indication = null, interactionSource = remember { MutableInteractionSource() }, onClick = onSelect)) {
        Column(Modifier.padding(Space.m), verticalArrangement = Arrangement.spacedBy(Space.s)) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Text(mode.name.ifEmpty { "Untitled" }.asCopy(), style = ObText.body.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
                    Text(mode.subtitle.asCopy(), style = ObText.subhead, color = colors.inkSecondary)
                }
                RadioMark(active)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    (if (mode.kind == BlockMode.Kind.ALLOW_ONLY) "Allow only selected" else "Block selected").asCopy(),
                    style = ObText.footnote,
                    color = colors.inkTertiary,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    "Edit".asCopy(),
                    style = ObText.footnote.copy(fontWeight = FontWeight.SemiBold),
                    color = colors.ink,
                    modifier = Modifier
                        .background(colors.fillQuiet, androidx.compose.foundation.shape.RoundedCornerShape(50))
                        .clickable(onClick = onEdit)
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                        .testTag("mode_edit")
                )
            }
        }
    }
}

@Composable
private fun RadioMark(on: Boolean) {
    val colors = obColors()
    Box(
        Modifier
            .size(22.dp)
            .background(if (on) colors.ink else androidx.compose.ui.graphics.Color.Transparent, CircleShape)
            .then(
                if (!on) Modifier.background(androidx.compose.ui.graphics.Color.Transparent, CircleShape)
                else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        if (on) GlyphIcon(Glyph.Check, colors.inkInverse, size = 10.dp)
        else Box(Modifier.size(22.dp).background(colors.inkTertiary.copy(alpha = 0.3f), CircleShape))
    }
}

@Composable
fun TemplatePickerContent(onClose: () -> Unit, onChoose: (ModeTemplate) -> Unit, modifier: Modifier = Modifier) {
    val colors = obColors()
    Column(modifier.fillMaxSize().background(colors.sheet).testTag("mode_templates")) {
        SheetHeader("New mode", onClose)
        ScrollColumn {
            Text(
                "Start from a template. You can rename it and change everything later.".asCopy(),
                style = ObText.footnote.copy(fontWeight = FontWeight.Normal),
                color = colors.inkSecondary
            )
            Spacer(Modifier.height(Space.s))
            ModeTemplate.entries.forEach { template ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(bottom = Space.s)
                        .background(colors.surface, androidx.compose.foundation.shape.RoundedCornerShape(24.dp))
                        .clickable { onChoose(template) }
                        .padding(Space.m)
                        .testTag("mode-template-${template.raw}"),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(Space.s)
                ) {
                    IconTile(ModeTemplateGlyph(template.raw), size = 40.dp)
                    Column(Modifier.weight(1f)) {
                        Text(template.title.asCopy(), style = ObText.body.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
                        Text(template.summary.asCopy(), style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkSecondary)
                    }
                    GlyphIcon(Glyph.Chevron, colors.inkTertiary, size = 12.dp)
                }
            }
            Spacer(Modifier.height(Space.l))
        }
    }
}

@Composable
fun ModeEditFlow(
    existing: BlockMode?,
    onClose: () -> Unit,
    onPickApps: (BlockMode.Kind, Set<String>, (Set<String>) -> Unit) -> Unit
) {
    var template by remember { mutableStateOf<ModeTemplate?>(null) }
    var name by remember { mutableStateOf(existing?.name ?: "") }
    var kind by remember { mutableStateOf(existing?.kind ?: BlockMode.Kind.BLOCK) }
    var packages by remember { mutableStateOf(existing?.packages ?: emptySet()) }
    var websites by remember { mutableStateOf(existing?.websites ?: emptyList()) }
    var addsSchedule by remember { mutableStateOf(false) }

    if (existing == null && template == null) {
        TemplatePickerContent(onClose = onClose, onChoose = { chosen ->
            template = chosen
            name = chosen.modeName
            kind = chosen.kind
            packages = emptySet()
            websites = emptyList()
            addsSchedule = false
            if (chosen.opensAppPicker) {
                onPickApps(chosen.kind, emptySet()) { packages = it }
            }
        })
        return
    }

    ModeEditContent(
        isNew = existing == null,
        name = name,
        onName = { name = it },
        kind = kind,
        onKind = { kind = it },
        packages = packages,
        websites = websites,
        onPickApps = { onPickApps(kind, packages) { packages = it } },
        onAddWebsite = { raw ->
            val host = DomainMatch.normalizeRule(raw) ?: return@ModeEditContent false
            if (websites.any { DomainMatch.matches(host, it) }) return@ModeEditContent false
            websites = websites + host
            true
        },
        onRemoveWebsite = { site -> websites = websites.filterNot { it == site } },
        scheduleSummary = if (existing == null) template?.scheduleSummary else null,
        addsSchedule = addsSchedule,
        onAddsSchedule = { addsSchedule = it },
        onBackToTemplates = if (existing == null) ({ template = null }) else null,
        onDelete = if (existing != null && !existing.isDefault) {
            {
                ModeRepository.delete(existing)
                onClose()
            }
        } else {
            null
        },
        onClose = onClose,
        onSave = {
            val valid = ModeName.validated(name) ?: return@ModeEditContent
            if (existing != null) {
                ModeRepository.update(existing.copy(name = valid, kind = kind, packages = packages, websites = websites))
            } else {
                val created = BlockMode(name = valid, kind = kind, packages = packages, websites = websites)
                ModeRepository.add(created)
                val t = template
                if (addsSchedule && t != null) {
                    t.suggestedSchedule(created)?.let { ScheduleRepository.add(it) }
                }
            }
            onClose()
        }
    )
}

@Composable
fun ModeEditContent(
    isNew: Boolean,
    name: String,
    onName: (String) -> Unit,
    kind: BlockMode.Kind,
    onKind: (BlockMode.Kind) -> Unit,
    packages: Set<String>,
    websites: List<String>,
    onPickApps: () -> Unit,
    onAddWebsite: (String) -> Boolean,
    onRemoveWebsite: (String) -> Unit,
    scheduleSummary: String?,
    addsSchedule: Boolean,
    onAddsSchedule: (Boolean) -> Unit,
    onBackToTemplates: (() -> Unit)?,
    onDelete: (() -> Unit)? = null,
    onClose: () -> Unit,
    onSave: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val draft = BlockMode(name = name.ifBlank { "Untitled" }, kind = kind, packages = packages, websites = websites)
    var draftSite by remember { mutableStateOf("") }
    Column(modifier.fillMaxSize().background(colors.sheet).testTag("mode_edit")) {
        SheetHeader(
            title = if (isNew) "New mode" else "Edit mode",
            onClose = onClose,
            onLeading = onBackToTemplates
        )
        ScrollColumn {
            SettingsGroup {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = Space.m).height(54.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Name", style = ObText.subhead, color = colors.inkSecondary, modifier = Modifier.weight(1f))
                    TextField(
                        value = name,
                        onValueChange = onName,
                        placeholder = { Text(ModeName.placeholder, style = ObText.subhead, color = colors.inkTertiary) },
                        singleLine = true,
                        textStyle = ObText.subhead.copy(fontWeight = FontWeight.SemiBold, color = colors.ink),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent
                        ),
                        modifier = Modifier.testTag("mode_name")
                    )
                }
            }
            Spacer(Modifier.height(Space.s))
            SettingsGroup {
                Column(Modifier.padding(Space.m), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                    Text("Behavior", style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
                    Text("Choose what this mode limits while you're blocked.", style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkSecondary)
                    SegmentedPill(
                        options = listOf("Block selected" to BlockMode.Kind.BLOCK, "Allow only selected" to BlockMode.Kind.ALLOW_ONLY),
                        selected = kind,
                        onSelect = onKind
                    )
                }
                HairlineDivider()
                SettingsRow(
                    Glyph.Grid,
                    if (kind == BlockMode.Kind.BLOCK) "Blocked apps and sites" else "Allowed apps",
                    detail = draft.pickedSummary(),
                    onClick = onPickApps
                )
                InfoNote(
                    if (kind == BlockMode.Kind.BLOCK) "Only what you pick is blocked. Everything else works as usual."
                    else "Everything is blocked except the apps you pick.",
                    Modifier.padding(Space.m)
                )
            }
            Spacer(Modifier.height(Space.s))
            SettingsGroup {
                SettingsRow(
                    Glyph.Globe,
                    "Websites",
                    subtitle = if (kind == BlockMode.Kind.BLOCK) {
                        "These domains are blocked while this mode is on."
                    } else {
                        "Only these domains are allowed. Other sites are blocked."
                    },
                    detail = if (websites.isEmpty()) "None" else "${websites.size}",
                    chevron = false
                )
                websites.forEach { site ->
                    HairlineDivider()
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = Space.m)
                            .height(48.dp)
                            .testTag("website_row"),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(site.asCopy(), style = ObText.subhead, color = colors.ink, modifier = Modifier.weight(1f))
                        Text(
                            "Remove".asCopy(),
                            style = ObText.footnote.copy(fontWeight = FontWeight.SemiBold),
                            color = colors.inkSecondary,
                            modifier = Modifier
                                .clickable { onRemoveWebsite(site) }
                                .padding(Space.xs)
                                .testTag("website_remove")
                        )
                    }
                }
                HairlineDivider()
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = Space.m).height(54.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(Space.s)
                ) {
                    TextField(
                        value = draftSite,
                        onValueChange = { draftSite = it },
                        placeholder = { Text("example.com", style = ObText.subhead, color = colors.inkTertiary) },
                        singleLine = true,
                        textStyle = ObText.subhead.copy(color = colors.ink),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent
                        ),
                        modifier = Modifier.weight(1f).testTag("website_input")
                    )
                    Text(
                        "Add".asCopy(),
                        style = ObText.footnote.copy(fontWeight = FontWeight.SemiBold),
                        color = colors.ink,
                        modifier = Modifier
                            .background(colors.fillQuiet, androidx.compose.foundation.shape.RoundedCornerShape(50))
                            .clickable {
                                if (onAddWebsite(draftSite)) draftSite = ""
                            }
                            .padding(horizontal = 14.dp, vertical = 8.dp)
                            .testTag("website_add")
                    )
                }
            }
            if (scheduleSummary != null) {
                Spacer(Modifier.height(Space.s))
                SettingsGroup {
                    SettingsToggleRow(
                        Glyph.Calendar,
                        "Schedule it",
                        checked = addsSchedule,
                        onCheckedChange = onAddsSchedule,
                        subtitle = "$scheduleSummary. Change it any time in Schedule.",
                        testTag = "mode_schedule"
                    )
                }
            }
            Spacer(Modifier.height(Space.m))
            PrimaryButton(
                "Save mode",
                emphasis = ButtonEmphasis.INK,
                enabled = ModeName.validated(name) != null,
                onClick = onSave
            )
            if (onDelete != null) {
                Spacer(Modifier.height(Space.s))
                PrimaryButton("Delete mode", onClick = onDelete)
            }
            Spacer(Modifier.height(Space.l))
        }
    }
}
