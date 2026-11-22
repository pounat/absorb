import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'tv_book_screen.dart';
import 'tv_cover_tile.dart';
import 'tv_focus_ring.dart';
import 'tv_home_screen.dart' show tvFocusTabs;
import 'tv_focusable.dart';

/// Search the library with the TV's keyboard; results as covers below.
class TvSearchScreen extends StatefulWidget {
  const TvSearchScreen({super.key});

  @override
  State<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends State<TvSearchScreen> {
  final _query = TextEditingController();
  final _firstResult = FocusNode(debugLabel: 'first search result');
  final _field = FocusNode(debugLabel: 'search box');
  // Typing only after OK on the box, so landing on it doesn't throw the
  // keyboard up and keep the arrows.
  bool _editing = false;
  bool _jumpWhenFound = false;
  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  bool _searching = false;
  int _gen = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _firstResult.dispose();
    _field.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    final api = context.read<AuthProvider>().apiService;
    final libId = context.read<LibraryProvider>().selectedLibraryId;
    final gen = ++_gen;
    if (q.isNotEmpty && (api == null || libId == null)) {
      debugPrint('[TV] search "$q" skipped: api=${api != null} library=$libId');
    }
    if (q.isEmpty || api == null || libId == null) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    var data = await api.searchLibrary(libId, q, limit: 40);
    // No answer at all (not an empty one): once more before giving up.
    if (data == null && mounted && gen == _gen) {
      debugPrint('[TV] search "$q" got no answer, trying again');
      data = await api.searchLibrary(libId, q, limit: 40);
    }
    if (!mounted || gen != _gen) return;
    final found = <Map<String, dynamic>>[];
    for (final group in ['book', 'podcast']) {
      for (final r in (data?[group] as List? ?? const [])) {
        final item = r is Map ? (r['libraryItem'] ?? r) : null;
        if (item is Map<String, dynamic>) found.add(item);
      }
    }
    debugPrint('[TV] search "$q" in $libId: ${data == null ? 'no answer' : '${found.length} found'}');
    setState(() {
      _results = found;
      _searching = false;
    });
    if (_jumpWhenFound && found.isNotEmpty) {
      _jumpWhenFound = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _firstResult.requestFocus();
      });
    }
  }

  void _startTyping() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  /// The box takes the remote only to type: OK opens the keyboard, up goes
  /// to the tabs and down to the results, and side to side moves the cursor
  /// only while typing.
  KeyEventResult _onFieldKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      tvFocusTabs.value++;
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      if (_results.isNotEmpty) _firstResult.requestFocus();
      return KeyEventResult.handled;
    }
    if (!_editing) {
      if (event is KeyDownEvent &&
          (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter)) {
        _startTyping();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight) return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 4, 56, 20),
          child: SizedBox(
            width: 620,
            child: Focus(
              onKeyEvent: _onFieldKey,
              skipTraversal: true,
              onFocusChange: (has) {
                if (!has && _editing) setState(() => _editing = false);
              },
              child: TvDrawsOwnFocus(
              child: TextField(
                controller: _query,
                focusNode: _field,
                readOnly: !_editing,
                showCursor: _editing,
                enableInteractiveSelection: false,
                textInputAction: TextInputAction.search,
                style: tt.titleLarge,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l.tvSearchHint,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: cs.onSurface, width: 3),
                  ),
                ),
                onChanged: _changed,
                // The keyboard's Search key: go to the results once they're in.
                onSubmitted: (_) {
                  _debounce?.cancel();
                  setState(() => _editing = false);
                  _jumpWhenFound = true;
                  _search();
                },
              ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: _searching
                      ? const CircularProgressIndicator()
                      : Text(_query.text.trim().isEmpty ? '' : l.tvNothingHere, style: tt.titleMedium),
                )
              : TvScrollFocusGroup(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(56, 20, 56, 140),
                    // Clipped, or covers scroll up over the tab bar.
                    clipBehavior: Clip.hardEdge,
                    cacheExtent: 900,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 28,
                      crossAxisSpacing: 28,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, i) => TvCoverTile(
                      item: _results[i],
                      focusNode: i == 0 ? _firstResult : null,
                      onSelect: () => openTvBook(context, _results[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
