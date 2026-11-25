from pathlib import Path
import subprocess,json
s=Path(__file__).resolve().parents[1];a=(s/'lib/services/bookorbit_api_service.dart').read_text()
method=a[a.index('  Future<({MediaOverlay overlay, int fileId, Map<String, dynamic> info,'):a.index('  Future<MediaOverlay?> narrationFor')]
helper=a[a.index('  Future<MediaOverlay?> readAlongTimingsFor'):a.index('  /// Public for the reader')]
fixture={'id':417,'files':[{'id':3710,'format':'epub','role':'primary'},{'id':3711,'format':'mp3','role':'content','durationSeconds':80},{'id':3837,'format':'epub','role':'content','mediaOverlay':{'available':True,'durationSeconds':80}}],'readAloudSync':{'state':'enabled','overlayFileId':3837,'audioDurationSeconds':80,'overlayDurationSeconds':80}}
code="""import 'dart:convert';
import 'lib/services/bookorbit_mapper.dart';
import 'lib/services/media_overlay.dart';
void debugPrint(String x) {}
const kIsWeb=true;
REVISION_HELPER
class _BoHttpError implements Exception {final int status;_BoHttpError(this.status);}
class Probe {
final Map<String,dynamic> detail;
Probe(this.detail);
final calls=<String>[];
final _v1='/bookorbit/sessions/synthetic-a/api/v1';
String _key(String b)=>b;
void _checkWebOwner(){}
final _readAlongTimings=<String,({MediaOverlay overlay,int fileId,double audio})>{};
Future<Map<String,dynamic>> _detail(String b) async=>detail;
Future<Map<String,dynamic>?> getLibraryItem(String b) async=>BookOrbitMapper.item(detail:detail);
MediaOverlay get overlay=>MediaOverlay.fromBookOrbit({'items':[{'sectionIndex':0,'textHref':'EPUB/c.xhtml','textFragment':'first','audioHref':'EPUB/a.m4a','clipBeginSeconds':0,'clipEndSeconds':40},{'sectionIndex':1,'textHref':'EPUB/d.xhtml','textFragment':'saved','audioHref':'EPUB/b.m4a','clipBeginSeconds':0,'clipEndSeconds':40}]})!;
Future<MediaOverlay?> _overlayOf(String b,int f) async=>overlay;
Future<({MediaOverlay overlay,int fileId})?> _narration(String b) async {final media=BookOrbitMapper.item(detail:detail)['media'] as Map;final n=media['narration'] as Map?;return n==null?null:(overlay:overlay,fileId:int.parse('${n['fileId']}'));}
Future<Map<String,dynamic>?> _manifest(String b) async=>{'assets':[{'assetId':'a','durationMs':40000},{'assetId':'b','durationMs':40000}]};
dynamic state={'assetId':'b','positionMs':15000,'revision':4};
Future<dynamic> _boGet(String path,[Map<String,String>? query]) async {calls.add(path);if(path.endsWith('playback-state'))return state;if(path.endsWith('/info'))return <String,dynamic>{};if(path.endsWith('/progress'))return [{'fileId':3837,'positionSeconds':0}];throw StateError(path);}
"""+helper+a[a.index('  String webReadAlongFailure('):a.index('  /// Read-only descriptor for native EPUB')]+method+"""}
void check(bool b,String why){if(!b)throw StateError(why);}
Future<void> main() async {
final sample=jsonDecode(r'''FIXTURE''') as Map<String,dynamic>;
final mapped=BookOrbitMapper.item(detail:sample)['media'] as Map;
check(mapped['narration']==null,'mixed never replaces audiobook narration');
check((mapped['readAlongEpub'] as Map)['fileId']=='3837','synthetic native resolves exact synchronized EPUB');
final p=Probe(sample);final d=await p.webReadAlong('417');
check(d!=null,'MIXED DESCRIPTOR MUST NOT BE NULL');
check(d!.fileId==3837,'correct generated EPUB');
check(d.base=='/bookorbit/sessions/synthetic-a/api/v1/epub/417/publication/3837/','publication retains selected account route');
check(p.calls.contains('/audiobooks/417/playback-state'),'reads native audiobook state');
check(!p.calls.contains('/books/417/progress'),'must not read stale EPUB position');
print('PASS synthetic native mapping and mixed descriptor');
final mixed=jsonDecode(jsonEncode(sample)) as Map<String,dynamic>;
mixed['readAloudSync']={'state':'enabled','overlayFileId':3837,'audioDurationSeconds':80,'overlayDurationSeconds':80};
final m=Probe(mixed);final before=jsonEncode(m.state);final md=await m.webReadAlong('417');
check(md!.initial?.fragment=='saved','track-local CAS 15s on second asset must open absolute55s chapter two');
check(jsonEncode(m.state)==before,'reader cannot mutate saved native state');
check(md.overlay.duration==80,'existing native helper overlay scale policy');
m.state=null;check((await m.webReadAlong('417'))!.initial==null,'confirmed no history selects first text without inventing progress');
for(final bad in [double.nan,-1,0.5,'15000']) {m.state={'assetId':'b','positionMs':bad,'revision':4};bool rejected=false;try{await m.webReadAlong('417');}catch(_){rejected=true;}check(rejected,'invalid position never resets or falls back to zero');}
m.state={'assetId':'missing','positionMs':15000,'revision':4};bool missingRejected=false;try{await m.webReadAlong('417');}catch(_){missingRejected=true;}check(missingRejected,'unknown asset never becomes local absolute fallback');
final epub=jsonDecode(jsonEncode(mixed)) as Map<String,dynamic>;epub['files']=(epub['files'] as List).where((f)=>f['id']==3837).toList();
final e=Probe(epub);final ed=await e.webReadAlong('417');check(ed!=null&&ed.fileId==3837,'EPUB-only descriptor remains supported');check(e.calls.contains('/books/417/progress')&&!e.calls.any((c)=>c.endsWith('playback-state')),'EPUB-only keeps native EPUB saved progress');
final plain=jsonDecode(jsonEncode(mixed)) as Map<String,dynamic>;plain['readAloudSync']={'state':'unavailable'};check(await Probe(plain).webReadAlong('417')==null,'unmatched audiobook cannot select unrelated narrated EPUB');
final ordinary=jsonDecode(jsonEncode(plain)) as Map<String,dynamic>;ordinary['files']=(ordinary['files'] as List).where((f)=>f['id']!=3837).toList();final ordinaryMedia=BookOrbitMapper.item(detail:ordinary)['media'] as Map;check((ordinaryMedia['audioFiles'] as List).isNotEmpty&&ordinaryMedia['narration']==null&&ordinaryMedia['readAlongEpub']==null,'ordinary audio plus plain EPUB remains a normal audiobook');check(await Probe(ordinary).webReadAlong('417')==null,'ordinary audio plus plain EPUB honestly unsupported');
check(p.webReadAlongFailure(_BoHttpError(401)).contains('Sign in again'),'only explicit unauthorized suggests sign in');
for(final error in [_BoHttpError(403),_BoHttpError(500),StateError('secret-url'),FormatException('private-body'),Exception('private-token')]) {final text=p.webReadAlongFailure(error);check(!text.contains('Sign in')&&!text.contains('secret-url')&&!text.contains('private-'),'sanitized non-auth diagnostics');}
print('PASS mixed saved absolute chapter, null history, invalid positions/assets, EPUB-only, unrelated audio rejection, zero mutations, static failure classification');
}
""".replace('FIXTURE',json.dumps(fixture))
code=code.replace('REVISION_HELPER',a[a.index('int bookOrbitWebRevision('):a.index('class _BoHttpError')])
# Exact descriptor/helper bodies and real mapper/MediaOverlay, with test-only I/O.
# Run after flutter pub get using the pinned SDK; no server or media writes.
import os
p=s/'mixed_probe.dart'
p.write_text(code)
try:
    raise SystemExit(subprocess.run([os.environ.get('DART','dart'),'run',str(p)],cwd=s).returncode)
finally:
    p.unlink(missing_ok=True)
