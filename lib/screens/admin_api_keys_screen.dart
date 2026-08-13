import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/overlay_toast.dart';

class AdminApiKeysScreen extends StatefulWidget {
  final List<dynamic> users;
  const AdminApiKeysScreen({super.key, required this.users});
  @override State<AdminApiKeysScreen> createState() => _AdminApiKeysScreenState();
}

class _AdminApiKeysScreenState extends State<AdminApiKeysScreen> {
  bool _loading = true;
  List<dynamic> _keys = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final keys = await api.getApiKeys();
    if (mounted) setState(() { _keys = keys; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: cs.primary,
        onPressed: _showEditor,
        child: Icon(Icons.add_rounded, color: cs.onPrimary),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.adminApiKeys, padding: EdgeInsets.zero)),
              IconButton(icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _keys.isEmpty
                        ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                            const SizedBox(height: 100),
                            Center(child: Icon(Icons.vpn_key_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.08))),
                            const SizedBox(height: 14),
                            Center(child: Text(l.adminApiKeysEmpty, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600))),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(l.adminApiKeysEmptySub, textAlign: TextAlign.center,
                                style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24))),
                            ),
                          ])
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _keys.length,
                            itemBuilder: (_, i) => _keyCard(cs, tt, _keys[i] as Map<String, dynamic>),
                          ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _keyCard(ColorScheme cs, TextTheme tt, Map<String, dynamic> key) {
    final l = AppLocalizations.of(context)!;
    final name = key['name'] as String? ?? l.unknown;
    final owner = (key['user'] as Map?)?['username'] as String? ?? '';
    final isActive = key['isActive'] as bool? ?? false;
    final expiresAt = DateTime.tryParse(key['expiresAt'] as String? ?? '');
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

    final (statusColor, statusLabel) = isExpired
        ? (Colors.orange, l.adminApiKeysExpired)
        : !isActive
            ? (cs.onSurfaceVariant, l.adminApiKeysInactive)
            : (const Color(0xFF4CAF50), l.adminApiKeysActive);

    final expiryStr = expiresAt != null ? l.adminApiKeysExpiresOn(_fmtDate(expiresAt)) : l.adminApiKeysNeverExpires;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.vpn_key_rounded, size: 18, color: statusColor.withValues(alpha: 0.9)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(statusLabel, style: tt.labelSmall?.copyWith(color: statusColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 3),
            if (owner.isNotEmpty)
              Text(
                owner,
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 1),
            Text(expiryStr, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.28), fontSize: 10)),
          ])),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'toggle') _toggleActive(key);
              else if (v == 'revoke') _revoke(key);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle', child: Row(children: [
                Icon(isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(isActive ? l.adminApiKeysSetInactive : l.adminApiKeysSetActive, style: TextStyle(color: cs.onSurface)),
              ])),
              PopupMenuItem(value: 'revoke', child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
                const SizedBox(width: 10),
                Text(l.adminApiKeysRevoke, style: TextStyle(color: Colors.red.shade300)),
              ])),
            ],
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> key) async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final id = key['id'] as String? ?? '';
    final ok = await api.updateApiKey(id, isActive: !(key['isActive'] as bool? ?? false));
    if (!mounted) return;
    if (ok) { _load(); } else { showOverlayToast(context, AppLocalizations.of(context)!.adminApiKeysFailedUpdate, icon: Icons.error_outline_rounded); }
  }

  Future<void> _revoke(Map<String, dynamic> key) async {
    final l = AppLocalizations.of(context)!;
    final name = key['name'] as String? ?? l.unknown;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminApiKeysDeleteTitle),
      content: Text(l.adminApiKeysDeleteContent(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.adminApiKeysRevoke, style: TextStyle(color: Colors.red.shade300))),
      ],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final ok = await api.deleteApiKey(key['id'] as String? ?? '');
    if (!mounted) return;
    final l2 = AppLocalizations.of(context)!;
    if (ok) { _load(); showOverlayToast(context, l2.adminApiKeysDeleted, icon: Icons.check_circle_outline_rounded); }
    else { showOverlayToast(context, l2.adminApiKeysFailedDelete, icon: Icons.error_outline_rounded); }
  }

  void _showEditor() {
    showAdaptiveActionMenu(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      desktopWidth: 560, desktopScrollWrap: false,
      builder: (_) => _ApiKeyEditorSheet(users: widget.users, onCreated: _load));
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

// ═══════════════════════════════════════════════════════════════
//  API Key Editor Sheet
// ═══════════════════════════════════════════════════════════════

class _ApiKeyEditorSheet extends StatefulWidget {
  final List<dynamic> users;
  final VoidCallback onCreated;
  const _ApiKeyEditorSheet({required this.users, required this.onCreated});
  @override State<_ApiKeyEditorSheet> createState() => _ApiKeyEditorSheetState();
}

class _ApiKeyEditorSheetState extends State<_ApiKeyEditorSheet> {
  final _nameCtrl = TextEditingController();
  String? _userId;
  int _expiryIndex = 0; // index into _expiryOptions
  bool _isActive = true;
  bool _saving = false;

  // (labelKey resolver, seconds or null)
  static const _expirySeconds = <int?>[null, 604800, 2592000, 7776000, 31536000];

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthProvider>().userId;
    // Fall back to the first user if the current id isn't in the list.
    final ids = widget.users.map((u) => u['id'] as String?).toSet();
    if (!ids.contains(_userId)) {
      _userId = widget.users.isNotEmpty ? widget.users.first['id'] as String? : null;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final expiryLabels = [l.adminApiKeysExpNever, l.adminApiKeysExp7d, l.adminApiKeysExp30d, l.adminApiKeysExp90d, l.adminApiKeysExp1y];

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [Expanded(child: Text(l.adminApiKeysNewTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)))])),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(cs, tt, l.adminApiKeysName), const SizedBox(height: 6),
            TextField(controller: _nameCtrl, style: TextStyle(color: cs.onSurface), decoration: _deco(cs, l.adminApiKeysNameHint)),
            const SizedBox(height: 20),
            _lbl(cs, tt, l.adminApiKeysOwner), const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: widget.users.map((u) {
              final id = u['id'] as String? ?? '';
              final uname = u['username'] as String? ?? l.unknown;
              final on = id == _userId;
              return GestureDetector(
                onTap: () => setState(() => _userId = id),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06))),
                  child: Text(uname, style: tt.labelMedium?.copyWith(
                    color: on ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7), fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            _lbl(cs, tt, l.adminApiKeysExpiration), const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(expiryLabels.length, (i) {
              final on = i == _expiryIndex;
              return GestureDetector(
                onTap: () => setState(() => _expiryIndex = i),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06))),
                  child: Text(expiryLabels[i], style: tt.labelMedium?.copyWith(
                    color: on ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7), fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            })),
            const SizedBox(height: 8),
            SwitchListTile(dense: true, contentPadding: EdgeInsets.zero,
              title: Text(l.adminApiKeysActive, style: TextStyle(color: cs.onSurface, fontSize: 14)),
              subtitle: Text(l.adminApiKeysActiveSub, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
              value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
          ]))),
        Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 12),
          child: SizedBox(width: double.infinity, height: 48, child: FilledButton(
            onPressed: _saving ? null : _create,
            style: FilledButton.styleFrom(backgroundColor: cs.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _saving
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
              : Text(l.adminApiKeysCreate, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onPrimary)),
          ))),
      ]));
  }

  Widget _lbl(ColorScheme cs, TextTheme tt, String t) => Text(t, style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600));

  InputDecoration _deco(ColorScheme cs, String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.2)),
    filled: true, fillColor: cs.onSurface.withValues(alpha: 0.04),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12));

  Future<void> _create() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final l = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { showOverlayToast(context, l.adminApiKeysNameRequired, icon: Icons.error_outline_rounded); return; }
    if (_userId == null) { showOverlayToast(context, l.adminApiKeysUserRequired, icon: Icons.error_outline_rounded); return; }
    setState(() => _saving = true);
    final created = await api.createApiKey(
      name: name, userId: _userId!, expiresIn: _expirySeconds[_expiryIndex], isActive: _isActive);
    if (!mounted) return;
    setState(() => _saving = false);
    final token = created?['apiKey'] as String?;
    if (created != null && token != null) {
      widget.onCreated();
      Navigator.pop(context);
      showAdaptiveActionMenu(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
        desktopWidth: 560,
        builder: (_) => _ApiKeyCreatedSheet(name: name, token: token));
    } else {
      showOverlayToast(context, l.adminApiKeysFailedCreate, icon: Icons.error_outline_rounded);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  API Key Created Sheet (token shown once)
// ═══════════════════════════════════════════════════════════════

class _ApiKeyCreatedSheet extends StatelessWidget {
  final String name;
  final String token;
  const _ApiKeyCreatedSheet({required this.name, required this.token});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_rounded, size: 20, color: Color(0xFF4CAF50))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.adminApiKeysCreated, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(name, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.withValues(alpha: 0.9)),
                const SizedBox(width: 10),
                Expanded(child: Text(l.adminApiKeysCopyWarning, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)))),
              ]),
            ),
            const SizedBox(height: 16),
            _lbl(cs, tt, l.adminApiKeysTokenLabel), const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08))),
              child: SelectableText(token, style: TextStyle(color: cs.onSurface, fontFamily: 'monospace', fontSize: 12, height: 1.4)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  showOverlayToast(context, l.adminApiKeysCopied, icon: Icons.check_circle_outline_rounded);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l.adminApiKeysCopy, style: const TextStyle(fontWeight: FontWeight.w700)),
              ))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 48, child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: cs.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(l.adminApiKeysDone, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onPrimary)),
              ))),
            ]),
          ]),
        ),
      ]));
  }

  Widget _lbl(ColorScheme cs, TextTheme tt, String t) => Text(t, style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600));
}
