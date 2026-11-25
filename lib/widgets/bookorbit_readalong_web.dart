// Browser-only trusted host. The iframe has no scripts and no media owner.
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/media_overlay.dart';

class BookOrbitReadAlongView extends StatefulWidget {
  final String itemId, title;
  const BookOrbitReadAlongView({super.key, required this.itemId, required this.title});
  @override
  State<BookOrbitReadAlongView> createState() => _BookOrbitReadAlongViewState();
}
class _BookOrbitReadAlongViewState extends State<BookOrbitReadAlongView> {
  final player = AudioPlayerService();
  BookOrbitApiService? api;
  String? owner;
  MediaOverlay? overlay;
  Map<String, dynamic>? item;
  Object? host;
  html.IFrameElement? frame;
  Timer? timer;
  String? error;
  bool follow = true, busy = false, retired = false;
  int generation = 0;
  bool get active {
    final selected = context.read<AuthProvider>().apiService;
    return !retired && api?.readAlongOwnerActive == true && selected is BookOrbitApiService && selected.readAlongOwnerKey == owner;
  }
  bool get playingThisBook {
    final current = player.currentApi;
    return active && player.currentItemId == widget.itemId && current is BookOrbitApiService && current.readAlongOwnerKey == owner;
  }
  @override
  void initState() {super.initState();timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());}
  Future<void> _load(html.IFrameElement element) async {
    frame = element;
    element.setAttribute('sandbox', 'allow-same-origin');
    element.setAttribute('title', 'Book text — Read Along');
    element.style.cssText = 'width:100%;height:100%;border:0;background:#101114';
    final selected = context.read<AuthProvider>().apiService;
    if (selected is! BookOrbitApiService) return;
    api = selected;owner = selected.readAlongOwnerKey;
    final mine = ++generation;
    try {
      final data = await selected.webReadAlong(widget.itemId);
      if (!mounted || mine != generation || !active) return;
      if (data == null) {
        setState(() => error = 'Read Along needs a synchronized EPUB matching this audiobook, or an EPUB with native narration.');
        return;
      }
      overlay = data.overlay;item = data.item;
      host = js.callMethod(js.getProperty(html.window, 'AbsorbReadAlong'), 'create', [element, data.base, js.jsify(data.info)]);
      final first = playingThisBook ? (overlay!.clipAt(player.position.inMilliseconds / 1000) ?? data.initial ?? overlay!.clips.first) : (data.initial ?? overlay!.clips.first);
      await _show(first);
      if (mounted && active) setState(() {});
    } catch (e) {if (mounted && mine == generation && active) setState(() => error = selected.webReadAlongFailure(e));}
  }
  Future<void> _show(OverlayClip clip) async {
    final h = host;if (h == null || !active) return;
    try {await js.promiseToFuture(js.callMethod(h, 'show', [clip.textHref, clip.fragment, follow]));}
    catch (_) {if (mounted && active) setState(() => error = 'Chapter text could not be loaded. Close and reopen Read Along to retry.');}
  }
  void _tick() {
    if (!mounted || api == null || retired) return;
    if (!active) {
      retired = true;generation++;final h = host;host = null;
      if (h != null) js.callMethod(h, 'dispose', []);
      setState(() => error = 'Account changed. Reopen this book from the selected account.');return;
    }
    if (playingThisBook && !player.isLoadingNewItem && error == null) {
      final clip = overlay?.clipAt(player.position.inMilliseconds / 1000);
      if (clip != null) unawaited(_show(clip));
    }
    setState(() {});
  }
  void _seek(double delta) {
    if (!mounted || !playingThisBook || busy || player.isLoadingNewItem || overlay == null) return;
    unawaited(player.seekTo(Duration(milliseconds: ((player.position.inMilliseconds / 1000 + delta).clamp(0, overlay!.duration) * 1000).round())));
  }
  Future<void> _play() async {
    if (!active || busy || item == null) return;
    setState(() => busy = true);
    try {
      if (playingThisBook) {
        if (player.isPlaying) {await player.pause();} else {await player.play(fromUi: true);}
      } else {
        final media = item!['media'] as Map? ?? {};
        final metadata = media['metadata'] as Map? ?? {};
        if (!active) return;
        final message = await player.playItem(api: api!, itemId: widget.itemId, title: widget.title,
          author: '${metadata['authorName'] ?? ''}', coverUrl: null,
          totalDuration: overlay!.duration, chapters: media['chapters'] as List? ?? [], fromUi: true);
        if (message != null && mounted && active) setState(() => error = message);
      }
    } finally {if (mounted) setState(() => busy = false);}
  }
  @override
  void dispose() {generation++;timer?.cancel();final h = host;if (h != null) js.callMethod(h, 'dispose', []);host = null;super.dispose();}
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff101114),
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: Column(children: [
      if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, semanticsLabel: error)),
      Expanded(child: HtmlElementView.fromTagName(tagName: 'iframe', onElementCreated: (e) => _load(e as html.IFrameElement))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Wrap(
        alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
          IconButton(tooltip: 'Back 10 seconds', onPressed: playingThisBook && !busy ? () => _seek(-10) : null, icon: const Icon(Icons.replay_10)),
          FilledButton.icon(onPressed: overlay != null && !busy && !retired ? _play : null,
            icon: Icon(playingThisBook && player.isPlaying ? Icons.pause : Icons.play_arrow), label: Text(playingThisBook && player.isPlaying ? 'Pause' : 'Play')),
          IconButton(tooltip: 'Forward 10 seconds', onPressed: playingThisBook && !busy ? () => _seek(10) : null, icon: const Icon(Icons.forward_10)),
          FilterChip(label: const Text('Follow narration'), selected: follow, onSelected: (v) => setState(() => follow = v)),
          const Text('Native passage timing'),
        ]))),
    ]),
  );
}
